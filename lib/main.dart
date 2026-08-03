import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma_embeddings/flutter_gemma_embeddings.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Hugging Face token for the gated Gemma3n repo, injected at build time:
  //   flutter run --dart-define-from-file=config.json
  const token = String.fromEnvironment('HUGGINGFACE_TOKEN');

  // Register the on-device embedding backend so the RAG methods work. The
  // Gecko/EmbeddingGemma embedder is what powers knowledge retrieval.
  FlutterGemma.initialize(
    huggingFaceToken: token.isNotEmpty ? token : null,
    maxDownloadRetries: 10,
    embeddingBackends: [LiteRtEmbeddingBackend()],
  );

  runApp(const CropSightApp());
}
