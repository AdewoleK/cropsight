import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../core/ai/gemma_service.dart';
import '../../core/rag/local_vector_index.dart';
import '../../core/rag/rag_service.dart';

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
  static const String _systemInstruction = '''
You are CropSight, an offline farming assistant for smallholder farmers.
Ground your answer ONLY in the reference cards provided. If they do not match
what was seen, say the match is uncertain and recommend a better photo or an
expert. Be practical and concise — a farmer is reading this in the field.

Answer with these short sections:
1. Crop
2. Likely problem
3. Confidence (low / medium / high) and why
4. What to do now (2-4 simple, low-cost steps)
5. Sources (name the reference card(s) you used)
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
