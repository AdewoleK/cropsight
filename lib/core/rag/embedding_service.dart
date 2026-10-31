import 'package:flutter_gemma/core/api/flutter_gemma.dart';

import '../ai/bundled_asset_copier.dart';
import 'embedding_catalog.dart';

/// Thin wrapper around flutter_gemma's on-device text embedder.
///
/// Uses the confirmed embedder API:
///   FlutterGemma.installEmbedder().modelFromBundled(..).tokenizerFromBundled(..).install()
///   FlutterGemma.getActiveEmbedder()  ->  embedder.generateEmbedding(text) -> List<double>
///
/// Requires `flutter_gemma_embeddings` to be added as a dependency and a
/// `LiteRtEmbeddingBackend()` registered in FlutterGemma.initialize (see main.dart).
class EmbeddingService {
  EmbeddingService._();
  static final EmbeddingService instance = EmbeddingService._();

  /// Install the embedding model + tokenizer from their bundled native
  /// assets (no network). On Android, pre-copies both ourselves on a
  /// background thread first — see [BundledAssetCopier] for why.
  Future<void> installEmbedder({void Function(int percent)? onProgress}) async {
    await BundledAssetCopier.ensureCopied(
      EmbeddingCatalog.modelFileName,
      onProgress: onProgress,
    );
    await BundledAssetCopier.ensureCopied(
      EmbeddingCatalog.tokenizerFileName,
      onProgress: onProgress,
    );
    await FlutterGemma.installEmbedder()
        .modelFromBundled(EmbeddingCatalog.modelFileName)
        .tokenizerFromBundled(EmbeddingCatalog.tokenizerFileName)
        .install();
  }

  /// Embed a single string into a 768-dim vector.
  Future<List<double>> embed(String text) async {
    // flutter_gemma only restores the active embedder on relaunch when its
    // file is in app documents; on iOS it's read from Bundle.main, so the
    // choice is lost. Re-registering is instant there (no copy).
    if (!FlutterGemma.hasActiveEmbedder()) await installEmbedder();
    final embedder = await FlutterGemma.getActiveEmbedder();
    return embedder.generateEmbedding(text);
  }
}
