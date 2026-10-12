/// What kind of problem a [KnowledgeCard] describes — used to filter the
/// library and to label cards.
enum CardKind {
  disease('Disease'),
  pest('Pest'),
  deficiency('Deficiency'),
  disorder('Disorder');

  const CardKind(this.label);
  final String label;
}

/// One crop-problem reference card. These are the "sources" the model cites,
/// and the entries of the browsable disease library.
class KnowledgeCard {
  const KnowledgeCard({
    required this.id,
    required this.crop,
    required this.title,
    required this.kind,
    required this.symptoms,
    required this.management,
    this.safety,
  });

  /// Stable short id, used for citation and for caching embeddings.
  final String id;

  /// Crop this card is about (e.g. "Cassava"), or "Many crops" for pests and
  /// deficiencies that hit several hosts.
  final String crop;

  /// Human-readable disease/problem name.
  final String title;

  final CardKind kind;

  /// What the farmer sees, and the cause/conditions behind it.
  final String symptoms;

  /// What to do, cheapest and lowest-risk first.
  final String management;

  /// Safety notes for any chemical control mentioned in [management]
  /// (protective gear, label rates, pre-harvest interval). Null when the
  /// management is non-chemical.
  final String? safety;

  /// The full reference text given to the model as grounding context.
  String get body => '$symptoms Management: $management'
      '${safety == null ? '' : ' Safety: $safety'}';

  /// Text used to build the embedding. Retrieval queries are descriptions of
  /// what a photo shows, so this keys on crop + title + symptoms only —
  /// management text would dilute the match (and the embedder truncates at
  /// 256 tokens).
  String get embeddingText => '$crop — $title\n$symptoms';

  /// Short label shown in the "Sources" list.
  String get label => '$crop: $title';
}
