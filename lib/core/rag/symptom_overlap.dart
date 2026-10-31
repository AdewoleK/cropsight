import 'dart:math';

import 'knowledge_card.dart';

/// Word overlap between a Lite-mode description and a card's symptoms.
///
/// The small on-device embedder ranks by overall meaning and can miss
/// decisive symptom words: "maize, ragged holes, caterpillars" once ranked a
/// virus above fall armyworm, whose card says exactly that. Mixing in word
/// overlap, weighted so rare words ("ragged", "pustules") count far more
/// than common ones ("leaves", "yellow"), pulls those cards up.
class SymptomOverlap {
  SymptomOverlap(List<KnowledgeCard> cards) {
    final docs = [for (final c in cards) contentWords(textOf(c))];
    final counts = <String, int>{};
    for (final d in docs) {
      for (final w in d) {
        counts[w] = (counts[w] ?? 0) + 1;
      }
    }
    _idf = {
      for (final e in counts.entries) e.key: log((docs.length + 1) / (e.value + 1)) + 1,
    };
    _unknownIdf = log(docs.length + 1) + 1;
  }

  late final Map<String, double> _idf;
  late final double _unknownIdf;

  /// How much overlap counts against embedding similarity when ranking.
  static const double weight = 0.3;

  static const _stopWords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from', 'in', 'is',
    'it', 'of', 'on', 'or', 'the', 'then', 'they', 'to', 'with', 'plant',
    'plants', 'problem',
  };

  static String textOf(KnowledgeCard c) => '${c.crop} ${c.title} ${c.symptoms}';

  /// Lower-case content words, with a crude plural strip so "holes" and
  /// "hole" meet.
  static Set<String> contentWords(String text) => {
        for (final w in text.toLowerCase().split(RegExp(r'[^a-z]+')))
          if (w.length > 2 && !_stopWords.contains(w))
            w.endsWith('s') && w.length > 4 ? w.substring(0, w.length - 1) : w,
      };

  /// Rarity-weighted share of the query's words found in [card], 0–1.
  double overlap(String query, KnowledgeCard card) {
    final q = contentWords(query);
    if (q.isEmpty) return 0;
    final c = contentWords(textOf(card));
    double hit = 0, total = 0;
    for (final w in q) {
      final idf = _idf[w] ?? _unknownIdf;
      total += idf;
      if (c.contains(w)) hit += idf;
    }
    return hit / total;
  }

  /// Ranking score for Lite mode: embedding similarity plus weighted overlap.
  double rankScore(double similarity, String query, KnowledgeCard card) =>
      similarity + weight * overlap(query, card);
}
