import 'package:cropsight/core/rag/knowledge_base.dart';
import 'package:cropsight/core/rag/symptom_overlap.dart';
import 'package:flutter_test/flutter_test.dart';

final _overlap = SymptomOverlap(KnowledgeBase.cards);
final _byId = {for (final c in KnowledgeBase.cards) c.id: c};

/// Ranks cards given embedding similarities logged from the real on-device
/// embedder for [query].
List<String> _rank(String query, Map<String, double> similarity) {
  final ids = similarity.keys.toList()
    ..sort((a, b) => _overlap
        .rankScore(similarity[b]!, query, _byId[b]!)
        .compareTo(_overlap.rankScore(similarity[a]!, query, _byId[a]!)));
  return ids;
}

void main() {
  test('rare symptom words outweigh common ones', () {
    final faw = _overlap.overlap('ragged holes', _byId['fall_armyworm']!);
    final mln = _overlap.overlap('ragged holes', _byId['maize_lethal_necrosis']!);
    expect(faw, greaterThan(mln));
  });

  test('maize with ragged holes puts fall armyworm first', () {
    // Similarities from the iPhone simulator, 31 Oct 2026. Without the
    // overlap re-rank, fall armyworm was outside the top five.
    const query = 'Maize plant. Problem on the leaves. holes, ragged chewed leaves.';
    final ranked = _rank(query, {
      'maize_lethal_necrosis': 0.851,
      'maize_stem_borer': 0.849,
      'fall_armyworm': 0.786,
      'maize_streak_virus': 0.831,
      'drought_stress': 0.825,
      'maize_gray_leaf_spot': 0.822,
      'zinc_deficiency': 0.815,
      'african_bollworm': 0.737,
    });
    expect(ranked.first, 'fall_armyworm');
    expect(ranked.indexOf('maize_lethal_necrosis'), greaterThan(1));
  });

  test('every card can be found by its own symptoms', () {
    for (final c in KnowledgeBase.cards) {
      expect(_overlap.overlap(c.symptoms, c), greaterThan(0.9), reason: c.id);
    }
  });
}
