import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/ai/gemma_service.dart';
import '../../core/rag/local_vector_index.dart';
import '../../core/rag/rag_service.dart';
import '../../core/sync/diagnosis_result.dart';
import '../../core/sync/sync_service.dart';
import 'structured_diagnosis.dart';

enum DiagnosisStatus { idle, looking, retrieving, answering, done, error }

/// Orchestrates the two-pass RAG diagnosis and exposes state to the UI:
///   1. vision describe -> 2. retrieve cards -> 3. grounded, cited answer.
class DiagnosisController extends ChangeNotifier {
  DiagnosisController({GemmaService? gemma, RagService? rag})
      : _gemma = gemma ?? GemmaService.instance,
        _rag = rag ?? RagService.instance;

  final GemmaService _gemma;
  final RagService _rag;

  DiagnosisStatus status = DiagnosisStatus.idle;
  Uint8List? imageBytes;
  String description = '';
  String answer = '';
  List<RetrievedCard> sources = const [];
  String? error;

  /// Persona + guardrails for the grounded pass. Deliberately humble: this is a
  /// field-guide assistant, not a certainty machine.
  ///
  /// The labeled-line format (rather than free markdown) is so
  /// [StructuredDiagnosis.tryParse] can reliably split this into distinct
  /// result cards instead of one block of text.
  static const String _systemInstruction = '''
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

  void setImage(Uint8List bytes) {
    imageBytes = bytes;
    description = '';
    answer = '';
    sources = const [];
    error = null;
    status = DiagnosisStatus.idle;
    notifyListeners();
  }

  Future<void> run() async {
    final bytes = imageBytes;
    if (bytes == null) return;

    error = null;
    answer = '';
    sources = const [];

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
        systemInstruction: _systemInstruction,
      );
      await for (final token in stream) {
        answer += token;
        notifyListeners();
      }

      status = DiagnosisStatus.done;
      unawaited(SyncService.instance.enqueueResult(DiagnosisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        description: description,
        answer: answer,
        citedCards: sources.map(CitedCard.fromRetrieved).toList(),
      )));
    } catch (e) {
      error = e.toString();
      status = DiagnosisStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    imageBytes = null;
    description = '';
    answer = '';
    sources = const [];
    error = null;
    status = DiagnosisStatus.idle;
    notifyListeners();
  }

  /// The answer parsed into distinct fields, or null if not done yet or the
  /// model didn't follow the requested format — callers should fall back to
  /// showing [answer] as raw text in that case.
  StructuredDiagnosis? get structured =>
      status == DiagnosisStatus.done ? StructuredDiagnosis.tryParse(answer) : null;

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
