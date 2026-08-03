import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';

import 'model_catalog.dart';

/// A thin, app-facing wrapper around flutter_gemma.
///
/// Two-pass RAG lives here:
///  - [describeImage]  (Pass 1): a vision call that turns the leaf photo into a
///    short text description we can use as a retrieval query.
///  - [answerGrounded] (Pass 2): a text-only call that produces the final
///    diagnosis, grounded in the retrieved knowledge cards and asked to cite them.
///
/// Everything here is local. After the model is installed once, no method needs
/// a network connection.
class GemmaService {
  GemmaService._();
  static final GemmaService instance = GemmaService._();

  InferenceModel? _model;

  /// True once the model file exists on the device.
  Future<bool> isModelInstalled() {
    return FlutterGemma.isModelInstalled(CropSightModel.fileName);
  }

  /// Download + install the model a single time (0..100 progress).
  Future<void> installModel({
    required void Function(int percent) onProgress,
    String? hfToken,
  }) async {
    await FlutterGemma.installModel(modelType: CropSightModel.modelType)
        .fromNetwork(CropSightModel.downloadUrl, token: hfToken)
        .withProgress(onProgress)
        .install();
  }

  /// Lazily create the on-device inference model (multimodal enabled).
  Future<InferenceModel> _ensureModel() async {
    return _model ??= await FlutterGemma.getActiveModel(
      maxTokens: CropSightModel.maxTokens,
      preferredBackend: CropSightModel.preferredBackend,
      supportImage: true,
    );
  }

  /// PASS 1 — vision. Look at the photo and return a short plain-text
  /// description (candidate crop + visible symptoms). Collected fully because
  /// we use it as a retrieval query, not for display.
  Future<String> describeImage({required Uint8List imageBytes}) async {
    final model = await _ensureModel();
    final chat = await model.createChat(
      supportImage: true,
      systemInstruction:
          'You are a plant-image describer. In 1-2 sentences, name the most '
          'likely crop and the visible leaf symptoms (colour, spots, pattern, '
          'wilting). Do not diagnose or give advice. If it is not a plant, say '
          '"not a plant".',
    );
    await chat.addQueryChunk(Message.withImage(
      text: 'Describe the crop and visible symptoms in this photo.',
      imageBytes: imageBytes,
      isUser: true,
    ));

    final buffer = StringBuffer();
    await for (final r in chat.generateChatResponseAsync()) {
      if (r is TextResponse) buffer.write(r.token);
    }
    return buffer.toString().trim();
  }

  /// PASS 2 — grounded answer. Given the Pass 1 description and the retrieved
  /// reference text, stream a final, cited diagnosis.
  Stream<String> answerGrounded({
    required String description,
    required String context,
    required String systemInstruction,
  }) async* {
    final model = await _ensureModel();
    final chat = await model.createChat(systemInstruction: systemInstruction);

    final prompt = 'Observed in the photo:\n$description\n\n'
        'Reference cards (use ONLY these to ground your answer):\n$context\n\n'
        'Now write the diagnosis using the required sections.';

    await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

    await for (final r in chat.generateChatResponseAsync()) {
      if (r is TextResponse) yield r.token;
    }
  }

  /// Free native resources.
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}
