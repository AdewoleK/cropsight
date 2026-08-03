import 'package:flutter_gemma/core/api/flutter_gemma.dart';

import 'embedding_catalog.dart';

/// Thin wrapper around flutter_gemma's on-device text embedder.
///
/// Uses the confirmed embedder API:
///   FlutterGemma.installEmbedder().modelFromNetwork(..).tokenizerFromNetwork(..).install()
///   FlutterGemma.getActiveEmbedder()  ->  embedder.generateEmbedding(text) -> List<double>
///
/// Requires `flutter_gemma_embeddings` to be added as a dependency and a
/// `LiteRtEmbeddingBackend()` registered in FlutterGemma.initialize (see main.dart).
class EmbeddingService {
  EmbeddingService._();
  static final EmbeddingService instance = EmbeddingService._();

  /// Download + install the embedding model + tokenizer once.
  Future<void> installEmbedder({
    void Function(int percent)? onProgress,
  }) async {
    final builder = FlutterGemma.installEmbedder()
        .modelFromNetwork(EmbeddingCatalog.modelUrl,
            token: EmbeddingCatalog.token)
        .tokenizerFromNetwork(EmbeddingCatalog.tokenizerUrl);
    if (onProgress != null) {
      builder.withModelProgress(onProgress);
      builder.withTokenizerProgress(onProgress);
    }
    await builder.install();
  }

  /// Embed a single string into a 768-dim vector.
  Future<List<double>> embed(String text) async {
    final embedder = await FlutterGemma.getActiveEmbedder();
    return embedder.generateEmbedding(text);
  }
}
