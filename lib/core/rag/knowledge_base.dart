import 'knowledge_card.dart';

/// The on-device knowledge base.
///
/// Kept as Dart data (rather than loose asset files) so it is guaranteed to be
/// available offline and needs no asset-manifest parsing. Content is concise,
/// field-oriented, and focused on Nigeria-relevant staples. Bump [version] when
/// you edit cards so cached embeddings are rebuilt.
class KnowledgeBase {
  const KnowledgeBase._();

  /// Increment whenever [cards] changes, so the vector index re-embeds.
  static const int version = 1;

  static const List<KnowledgeCard> cards = [
    KnowledgeCard(
      id: 'cassava_mosaic',
      crop: 'Cassava',
      title: 'Cassava mosaic disease',
      body:
          'A viral disease spread by whiteflies and infected cuttings. Leaves '
          'show a yellow-and-green mosaic pattern, become distorted, curled, and '
          'reduced in size. Growth is stunted and root yield drops sharply. '
          'Management: plant certified disease-free or resistant varieties (e.g. '
          'TME 419, improved TMS lines), remove and destroy infected plants '
          'early, and control whiteflies. Do not take cuttings from symptomatic '
          'plants.',
    ),
    KnowledgeCard(
      id: 'cassava_bacterial_blight',
      crop: 'Cassava',
      title: 'Cassava bacterial blight',
      body:
          'Caused by Xanthomonas bacteria, worsened by rain and wounds. Symptoms '
          'begin as angular water-soaked spots between leaf veins that turn brown, '
          'merge, and cause wilting, leaf death, and dark streaks along stems and '
          'petioles; gum may ooze from stems. Management: use clean, resistant '
          'planting material, practice crop rotation, avoid moving through wet '
          'fields, and remove infected debris. Avoid taking cuttings from affected '
          'stems.',
    ),
    KnowledgeCard(
      id: 'maize_streak_virus',
      crop: 'Maize',
      title: 'Maize streak virus',
      body:
          'A viral disease transmitted by leafhoppers. Young leaves develop rows '
          'of pale, broken yellow-white streaks running parallel to the veins; '
          'severe early infection stunts plants and reduces cob formation. '
          'Management: plant tolerant varieties, sow early and uniformly with the '
          'rains to avoid peak leafhopper pressure, control grassy weeds that host '
          'the vector, and remove volunteer maize.',
    ),
    KnowledgeCard(
      id: 'maize_leaf_blight',
      crop: 'Maize',
      title: 'Northern corn leaf blight',
      body:
          'A fungal disease (Exserohilum turcicum) favoured by humid, moderate '
          'temperatures. Symptoms are long, grey-green to tan, cigar-shaped '
          'lesions on the leaves that enlarge and can kill leaf tissue, cutting '
          'grain fill. Management: plant resistant hybrids, rotate away from maize, '
          'plough under or remove infected residue, and apply a foliar fungicide '
          'only if pressure is high and economically justified.',
    ),
    KnowledgeCard(
      id: 'tomato_late_blight',
      crop: 'Tomato',
      title: 'Late blight',
      body:
          'A fast-moving disease (Phytophthora infestans) that thrives in cool, '
          'wet, humid weather. Symptoms: large greasy grey-green to brown blotches '
          'on leaves and stems, often with a pale halo and white mould on the leaf '
          'underside in humidity; fruit shows firm brown greasy patches. Can '
          'destroy a crop in days. Management: remove and destroy infected plants '
          'immediately, improve airflow and drainage, avoid overhead watering, and '
          'apply protectant fungicide before symptoms in wet spells.',
    ),
    KnowledgeCard(
      id: 'tomato_early_blight',
      crop: 'Tomato',
      title: 'Early blight',
      body:
          'A fungal disease (Alternaria) common in warm, wet conditions, usually '
          'starting on older lower leaves. Symptoms: brown spots with concentric '
          'rings ("target spots") surrounded by yellowing; leaves dry and drop, '
          'exposing fruit to sunscald. Management: rotate crops, stake plants and '
          'remove lower affected leaves, mulch to stop soil splash, water at the '
          'base, and use fungicide if it spreads.',
    ),
    KnowledgeCard(
      id: 'pepper_bacterial_leaf_spot',
      crop: 'Pepper',
      title: 'Bacterial leaf spot',
      body:
          'Caused by Xanthomonas bacteria, spread by rain splash and handling. '
          'Symptoms: small water-soaked spots that become brown, angular, and '
          'scabby with a yellow margin on leaves; heavy infection causes leaf drop '
          'and blemished fruit. Management: use clean certified seed and '
          'transplants, rotate crops, avoid working plants when wet, remove crop '
          'debris, and consider copper-based sprays where approved.',
    ),
    KnowledgeCard(
      id: 'rice_blast',
      crop: 'Rice',
      title: 'Rice blast',
      body:
          'A serious fungal disease (Magnaporthe oryzae). Leaf symptoms are '
          'spindle- or diamond-shaped lesions with grey centres and brown '
          'margins; infection at the neck of the panicle ("neck blast") turns it '
          'brown and causes empty grain. Favoured by high humidity and excess '
          'nitrogen. Management: plant resistant varieties, split and moderate '
          'nitrogen, keep even flooding, and use a fungicide at booting if neck '
          'blast is a known risk.',
    ),
  ];
}
