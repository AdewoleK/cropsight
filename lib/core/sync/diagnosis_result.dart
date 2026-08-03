import '../rag/local_vector_index.dart';

/// A single cited knowledge-card hit, kept minimal enough to sync safely.
class CitedCard {
  const CitedCard({required this.id, required this.label, required this.score});

  factory CitedCard.fromRetrieved(RetrievedCard r) =>
      CitedCard(id: r.card.id, label: r.card.label, score: r.score);

  final String id;
  final String label;
  final double score;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'score': score};

  factory CitedCard.fromJson(Map<String, dynamic> json) => CitedCard(
        id: json['id'] as String,
        label: json['label'] as String,
        score: (json['score'] as num).toDouble(),
      );
}

/// A completed diagnosis, kept on-device with the full text (for the local
/// history screen) but only ever *transmitted* via [toSyncPayload], which
/// carries none of it — see the Privacy section in README.md: sync carries
/// "results only — never the image, never the raw inference." The free-text
/// vision description and diagnosis are the raw inference, so they never
/// leave the phone; only which knowledge cards matched does.
class DiagnosisResult {
  DiagnosisResult({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.answer,
    required this.citedCards,
    this.synced = false,
  });

  final String id;
  final DateTime timestamp;
  final String description;
  final String answer;
  final List<CitedCard> citedCards;
  bool synced;

  /// Full local record — stays on-device.
  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'answer': answer,
        'citedCards': citedCards.map((c) => c.toJson()).toList(),
        'synced': synced,
      };

  factory DiagnosisResult.fromLocalJson(Map<String, dynamic> json) =>
      DiagnosisResult(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        description: json['description'] as String,
        answer: json['answer'] as String,
        citedCards: (json['citedCards'] as List)
            .map((c) => CitedCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        synced: json['synced'] as bool,
      );

  /// The anonymised subset that actually leaves the phone: no photo, no
  /// vision description, no free-text diagnosis — just which reference cards
  /// matched and how well, tagged with the caller-supplied anonymous ID.
  Map<String, dynamic> toSyncPayload(String anonymousId) => {
        'anonymous_id': anonymousId,
        'timestamp': timestamp.toIso8601String(),
        'cited_cards': citedCards
            .map((c) => {'id': c.id, 'score': c.score})
            .toList(),
      };
}
