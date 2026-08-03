import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hugging Face token for the gated Gemma3n repo, injected at build time:
  //   flutter run --dart-define-from-file=config.json
  const token = String.fromEnvironment('HUGGINGFACE_TOKEN');

  // Register the on-device inference engine (MediaPipe .task, backing the
  // Gemma3n E2B model) and embedding backend (Gecko/EmbeddingGemma, powering
  // knowledge retrieval). Must be awaited: nothing else in the plugin is safe
  // to call until this completes.
  await FlutterGemma.initialize(
    huggingFaceToken: token.isNotEmpty ? token : null,
    maxDownloadRetries: 10,
    inferenceEngines: [const MediaPipeEngine()],
    embeddingBackends: [const LiteRtEmbeddingBackend()],
  );

  runApp(const CropSightApp());
}
