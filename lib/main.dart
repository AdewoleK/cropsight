import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the on-device inference engine (MediaPipe .task, backing the
  // Gemma3n E2B model) and embedding backend (Gecko/EmbeddingGemma, powering
  // knowledge retrieval). Both models ship as bundled native assets, so no
  // Hugging Face token is needed at runtime. Must be awaited: nothing else in
  // the plugin is safe to call until this completes.
  await FlutterGemma.initialize(
    inferenceEngines: [const MediaPipeEngine()],
    embeddingBackends: [const LiteRtEmbeddingBackend()],
  );

  runApp(const CropSightApp());
}
