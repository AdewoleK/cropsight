/// One crop-disease reference card. These are the "sources" the model cites.
class KnowledgeCard {
  const KnowledgeCard({
    required this.id,
    required this.crop,
    required this.title,
    required this.body,
  });

  /// Stable short id, used for citation and for caching embeddings.
  final String id;

  /// Crop this card is about (e.g. "Cassava").
  final String crop;

  /// Human-readable disease/problem name.
  final String title;

  /// The reference text that gets embedded and retrieved.
  final String body;

  /// Text used to build the embedding — crop + title + body so retrieval keys
  /// on all three.
  String get embeddingText => '$crop — $title\n$body';

  /// Short label shown in the "Sources" list.
  String get label => '$crop: $title';
}
