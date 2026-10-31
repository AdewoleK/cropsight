import 'embedding_service.dart';
import 'knowledge_base.dart';
import 'local_vector_index.dart';
import 'symptom_overlap.dart';

/// Orchestrates retrieval: make sure the embedder + index are ready, then turn
/// a text query into the most relevant knowledge cards.
class RagService {
  RagService._();
  static final RagService instance = RagService._();

  final SymptomOverlap _overlap = SymptomOverlap(KnowledgeBase.cards);

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

  /// Like [retrieve], but when [crop] is given only that crop's cards (plus
  /// "Many crops" pests and deficiencies) are considered — the farmer told
  /// us the crop, so a tomato card should never outrank a maize one.
  Future<List<RetrievedCard>> retrieveForCrop(
    String query, {
    String? crop,
    int k = 3,
  }) async {
    await ensureReady();
    final queryVec = await EmbeddingService.instance.embed(query);
    final all = LocalVectorIndex.instance.search(queryVec, k: 1 << 20);
    final candidates = all
        .where((r) => crop == null || r.card.crop == crop || r.card.crop == 'Many crops')
        .toList();
    // Re-rank with symptom word overlap (see symptom_overlap.dart). The
    // shown match score is the combined score, scaled back to 0–1, so the
    // percentages read in the same order as the list.
    final ranked = [
      for (final r in candidates)
        RetrievedCard(
            r.card,
            _overlap.rankScore(r.score, query, r.card) /
                (1 + SymptomOverlap.weight)),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return ranked.take(k).toList();
  }
}
