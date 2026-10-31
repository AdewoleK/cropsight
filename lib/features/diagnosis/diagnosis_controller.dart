import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/ai/gemma_service.dart';
import '../../core/ai/photo_quality.dart';
import '../../core/rag/local_vector_index.dart';
import '../../core/rag/rag_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/sync/diagnosis_result.dart';
import '../../core/sync/sync_service.dart';
import 'result_actions.dart';
import 'structured_diagnosis.dart';

enum DiagnosisStatus { idle, looking, retrieving, answering, done, error }

/// Orchestrates the two-pass RAG diagnosis and exposes state to the UI:
///   1. vision describe -> 2. retrieve cards -> 3. grounded, cited answer.
class DiagnosisController extends ChangeNotifier {
  DiagnosisController({
    required AppSettings settings,
    GemmaService? gemma,
    RagService? rag,
  })  : _settings = settings,
        _gemma = gemma ?? GemmaService.instance,
        _rag = rag ?? RagService.instance;

  final AppSettings _settings;
  final GemmaService _gemma;
  final RagService _rag;

  DiagnosisStatus status = DiagnosisStatus.idle;
  Uint8List? imageBytes;
  String description = '';
  String answer = '';
  List<RetrievedCard> sources = const [];
  String? error;

  /// Exposure/focus problems found in the picked photo, or null while the
  /// check is still running.
  List<PhotoIssue>? photoIssues;

  /// Language the current [answer] was written in.
  AnswerLanguage language = AnswerLanguage.english;

  /// Set once the current result has been saved to a field, so it isn't
  /// saved twice.
  String? savedToFieldId;

  /// Persona + guardrails for the grounded pass. Deliberately humble: this is a
  /// field-guide assistant, not a certainty machine.
  ///
  /// The labeled-line format (rather than free markdown) is so
  /// [StructuredDiagnosis.tryParse] can reliably split this into distinct
  /// result cards instead of one block of text.
  static const String _baseInstruction = '''
You are CropSight, an offline farming assistant for smallholder farmers.
Ground your answer ONLY in the reference cards provided. If they do not match
what was seen, say so plainly and recommend a better photo or an expert. Be
practical and concise — a farmer is reading this in the field.

Respond in EXACTLY this format, one field per line, nothing before or after:

CROP: <the crop, or "unknown">
PROBLEM: <the likely disease, pest, or deficiency, or "unclear match">
CONFIDENCE: <low, medium, or high>
WHY: <one short sentence for that confidence level>
STEPS:
- <first low-cost action>
- <second low-cost action>
- <optional third action>
SOURCES: <reference card name(s) you used, comma-separated>
''';

  /// Answers in a farmer's own language, but keeps the labels (and the
  /// confidence word) in English so [StructuredDiagnosis.tryParse] still
  /// works whatever the language.
  static String systemInstructionFor(AnswerLanguage language) {
    if (language == AnswerLanguage.english) return _baseInstruction;
    return '$_baseInstruction\n'
        'Write every value in ${language.promptName}, in simple everyday words. '
        'Keep the labels CROP, PROBLEM, CONFIDENCE, WHY, STEPS and SOURCES in '
        'English, write the CONFIDENCE value as the English word low, medium, '
        'or high, keep SOURCES as the English card names, and if nothing '
        'matches write PROBLEM as the English words "unclear match".\n';
  }

  Future<void> setImage(Uint8List bytes) async {
    imageBytes = bytes;
    description = '';
    answer = '';
    sources = const [];
    error = null;
    photoIssues = null;
    savedToFieldId = null;
    status = DiagnosisStatus.idle;
    notifyListeners();

    List<PhotoIssue> issues;
    try {
      issues = await PhotoQuality.check(bytes);
    } catch (_) {
      issues = const []; // Undecodable here — let the model try anyway.
    }
    // Ignore a stale result if a different photo was picked meanwhile.
    if (!identical(imageBytes, bytes)) return;
    photoIssues = issues;
    notifyListeners();
  }

  Future<void> run() async {
    final bytes = imageBytes;
    if (bytes == null) return;

    error = null;
    answer = '';
    sources = const [];
    savedToFieldId = null;
    language = _settings.language;

    try {
      // Pass 1 — vision.
      status = DiagnosisStatus.looking;
      notifyListeners();
      description = await _gemma.describeImage(imageBytes: bytes);

      // Retrieve.
      status = DiagnosisStatus.retrieving;
      notifyListeners();
      sources = await _rag.retrieve(description, k: 3);
      notifyListeners();

      final context = sources
          .map((s) => '- ${s.card.label}: ${s.card.body}')
          .join('\n');

      // Pass 2 — grounded, streaming.
      status = DiagnosisStatus.answering;
      notifyListeners();
      final stream = _gemma.answerGrounded(
        description: description,
        context: context,
        systemInstruction: systemInstructionFor(language),
      );
      await for (final token in stream) {
        answer += token;
        notifyListeners();
      }

      status = DiagnosisStatus.done;
      final structured = StructuredDiagnosis.tryParse(answer);
      final cited = reportedCards(sources, structured?.sourcesText);
      unawaited(SyncService.instance.enqueueResult(DiagnosisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        description: description,
        answer: answer,
        // Nothing cited: still send the top hit so it counts toward what
        // farmers report, but with no confidence it can't trigger an alert.
        citedCards: (cited.isEmpty ? sources.take(1) : cited)
            .map(CitedCard.fromRetrieved)
            .toList(),
        source: DiagnosisSource.photo,
        // The model's confidence is about the card it cited. If it cited none
        // of the retrieved cards, there's nothing it vouched for.
        confidence: cited.isEmpty ? null : structured?.confidenceLevel,
        unclear: structured?.problem?.toLowerCase().contains('unclear') ?? false,
      )));
    } catch (e) {
      error = e.toString();
      status = DiagnosisStatus.error;
    }
    notifyListeners();
  }

  /// The retrieved cards the model actually named in SOURCES, in its order.
  /// The report carries these rather than the top retrieval hit, so the
  /// problem sent matches the one the farmer was told about.
  static List<RetrievedCard> reportedCards(
      List<RetrievedCard> retrieved, String? sourcesText) {
    final named = (sourcesText ?? '').toLowerCase();
    final hits = retrieved
        .where((r) => named.contains(r.card.title.toLowerCase()))
        .toList()
      ..sort((a, b) => named
          .indexOf(a.card.title.toLowerCase())
          .compareTo(named.indexOf(b.card.title.toLowerCase())));
    return hits;
  }

  void reset() {
    imageBytes = null;
    description = '';
    answer = '';
    sources = const [];
    error = null;
    photoIssues = null;
    savedToFieldId = null;
    status = DiagnosisStatus.idle;
    notifyListeners();
  }

  void markSaved(String fieldId) {
    savedToFieldId = fieldId;
    notifyListeners();
  }

  /// The answer parsed into distinct fields, or null if not done yet or the
  /// model didn't follow the requested format — callers should fall back to
  /// showing [answer] as raw text in that case.
  StructuredDiagnosis? get structured =>
      status == DiagnosisStatus.done ? StructuredDiagnosis.tryParse(answer) : null;

  /// The finished result in the shape [ResultActions] needs.
  ResultSummary get summary {
    final s = structured;
    final spoken = s == null
        ? answer
        : [
            if (s.crop != null) s.crop!,
            if (s.problem != null) s.problem!,
            if (s.confidenceReason != null) s.confidenceReason!,
            ...s.steps,
          ].join('. ');
    final share = StringBuffer();
    if (s == null) {
      share.writeln(answer.trim());
    } else {
      if (s.crop != null) share.writeln('Crop: ${s.crop}');
      if (s.problem != null) share.writeln('Likely problem: ${s.problem}');
      if (s.confidenceLevel != null) {
        share.writeln('Confidence: ${s.confidenceLevel}'
            '${s.confidenceReason == null ? '' : ' — ${s.confidenceReason}'}');
      }
      if (s.steps.isNotEmpty) {
        share.writeln('What to do:');
        for (var i = 0; i < s.steps.length; i++) {
          share.writeln('${i + 1}. ${s.steps[i]}');
        }
      }
    }
    if (sources.isNotEmpty) {
      share.writeln('Field guide: ${sources.map((r) => r.card.label).join('; ')}');
    }
    share.write('\n$shareFooter');
    return ResultSummary(
      spokenText: spoken,
      shareText: share.toString(),
      language: language,
      photo: imageBytes,
      crop: s?.crop,
      problem: s?.problem,
      confidence: s?.confidenceLevel,
    );
  }

  String get statusLabel {
    switch (status) {
      case DiagnosisStatus.looking:
        return 'Looking at the photo…';
      case DiagnosisStatus.retrieving:
        return 'Checking the field guide…';
      case DiagnosisStatus.answering:
        return 'Writing the diagnosis…';
      case DiagnosisStatus.done:
        return 'Diagnosis';
      case DiagnosisStatus.error:
        return 'Error';
      case DiagnosisStatus.idle:
        return '';
    }
  }
}
