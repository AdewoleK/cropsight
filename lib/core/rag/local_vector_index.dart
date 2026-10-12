import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import 'embedding_service.dart';
import 'knowledge_base.dart';
import 'knowledge_card.dart';

/// A hit returned from the index: the card plus its similarity score (0..1).
class RetrievedCard {
  const RetrievedCard(this.card, this.score);
  final KnowledgeCard card;
  final double score;
}

/// A tiny on-device vector index over the knowledge base.
///
/// For a few dozen short cards, brute-force cosine similarity is instant and
/// avoids a native vector-store dependency. Embeddings are computed once and
/// cached on disk, so subsequent launches are fast. If the KB grows to
/// thousands of chunks, swap this for `flutter_gemma_rag_sqlite`.
class LocalVectorIndex {
  LocalVectorIndex._();
  static final LocalVectorIndex instance = LocalVectorIndex._();

  final Map<String, List<double>> _vectors = {};
  bool _ready = false;
  Future<void>? _building;

  bool get isReady => _ready;

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/kb_vectors_v${KnowledgeBase.version}.json');
  }

  /// Build the index (embedding every card) or load it from cache.
  ///
  /// [onProgress] reports 0..100 while embedding on a cold build. Concurrent
  /// callers share one build (only the first caller's [onProgress] fires).
  Future<void> ensureBuilt({void Function(int percent)? onProgress}) {
    if (_ready) return Future.value();
    return _building ??= _build(onProgress).whenComplete(() => _building = null);
  }

  Future<void> _build(void Function(int percent)? onProgress) async {

    // Try cache first.
    final file = await _cacheFile();
    if (await file.exists()) {
      try {
        final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        raw.forEach((id, v) {
          _vectors[id] = (v as List).map((e) => (e as num).toDouble()).toList();
        });
        if (_vectors.length == KnowledgeBase.cards.length) {
          _ready = true;
          onProgress?.call(100);
          return;
        }
        _vectors.clear(); // stale cache, rebuild
      } catch (_) {
        _vectors.clear();
      }
    }

    // Cold build: embed each card.
    const cards = KnowledgeBase.cards;
    for (var i = 0; i < cards.length; i++) {
      final vec = await EmbeddingService.instance.embed(cards[i].embeddingText);
      _vectors[cards[i].id] = vec;
      onProgress?.call(((i + 1) / cards.length * 100).round());
    }

    await file.writeAsString(jsonEncode(_vectors));
    _ready = true;
  }

  /// Return the top-[k] most similar cards to [queryVector].
  List<RetrievedCard> search(List<double> queryVector, {int k = 3}) {
    final hits = <RetrievedCard>[];
    for (final card in KnowledgeBase.cards) {
      final vec = _vectors[card.id];
      if (vec == null) continue;
      hits.add(RetrievedCard(card, _cosine(queryVector, vec)));
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(k).toList();
  }

  double _cosine(List<double> a, List<double> b) {
    var dot = 0.0, na = 0.0, nb = 0.0;
    final n = min(a.length, b.length);
    for (var i = 0; i < n; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (sqrt(na) * sqrt(nb));
  }
}
