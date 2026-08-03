import 'embedding_service.dart';
import 'local_vector_index.dart';

/// Orchestrates retrieval: make sure the embedder + index are ready, then turn
/// a text query into the most relevant knowledge cards.
class RagService {
  RagService._();
  static final RagService instance = RagService._();

  /// Ensure the vector index is built (embedder must already be installed).
  Future<void> ensureReady({void Function(int percent)? onProgress}) {
    return LocalVectorIndex.instance.ensureBuilt(onProgress: onProgress);
  }

  /// Retrieve the top-[k] cards for a free-text query (e.g. the vision pass's
  /// candidate description).
  Future<List<RetrievedCard>> retrieve(String query, {int k = 3}) async {
    await ensureReady();
    final queryVec = await EmbeddingService.instance.embed(query);
    return LocalVectorIndex.instance.search(queryVec, k: k);
  }
}
