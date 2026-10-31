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

/// How a diagnosis was reached: the photo model, or the farmer picking a
/// match themselves in Lite mode.
enum DiagnosisSource { photo, lite }

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
    this.source = DiagnosisSource.photo,
    this.confidence,
    this.unclear = false,
    this.statePcode,
    this.lgaPcode,
    this.shared = false,
    this.synced = false,
  });

  final String id;
  final DateTime timestamp;
  final String description;
  final String answer;
  final List<CitedCard> citedCards;
  final DiagnosisSource source;

  /// The model's own low/medium/high, when it gave one.
  final String? confidence;

  /// True when the model found no card that fits ("unclear match"). A cluster
  /// of these can mean something the field guide doesn't cover.
  final bool unclear;

  /// Where the farmer said they farm when this was diagnosed (OCHA P-codes).
  final String? statePcode;
  final String? lgaPcode;

  /// Whether the farmer had reporting switched on at the time. Results made
  /// with it off are never sent, even if they switch it on later.
  final bool shared;
  bool synced;

  /// Whether this result may leave the phone: consent given and an LGA set.
  bool get reportable => shared && lgaPcode != null;

  /// Full local record — stays on-device.
  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'answer': answer,
        'citedCards': citedCards.map((c) => c.toJson()).toList(),
        'source': source.name,
        'confidence': confidence,
        'unclear': unclear,
        'statePcode': statePcode,
        'lgaPcode': lgaPcode,
        'shared': shared,
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
        source: DiagnosisSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => DiagnosisSource.photo,
        ),
        confidence: json['confidence'] as String?,
        unclear: json['unclear'] as bool? ?? false,
        statePcode: json['statePcode'] as String?,
        lgaPcode: json['lgaPcode'] as String?,
        shared: json['shared'] as bool? ?? false,
        synced: json['synced'] as bool,
      );

  /// Copy with where the farmer is and whether they consented, stamped at the
  /// moment of diagnosis.
  DiagnosisResult withReporting({
    required bool shared,
    String? statePcode,
    String? lgaPcode,
  }) =>
      DiagnosisResult(
        id: id,
        timestamp: timestamp,
        description: description,
        answer: answer,
        citedCards: citedCards,
        source: source,
        confidence: confidence,
        unclear: unclear,
        statePcode: statePcode,
        lgaPcode: lgaPcode,
        shared: shared,
        synced: synced,
      );

  /// The anonymised subset that actually leaves the phone: no photo, no
  /// vision description, no free-text diagnosis — just which reference cards
  /// matched and how well, how sure the model was, and the farmer's LGA,
  /// tagged with the caller-supplied anonymous ID.
  Map<String, dynamic> toSyncPayload(String anonymousId) => {
        'id': id,
        'anonymous_id': anonymousId,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'source': source.name,
        'confidence': confidence,
        'unclear': unclear,
        'state_pcode': statePcode,
        'lga_pcode': lgaPcode,
        'cited_cards': citedCards
            .map((c) => {'id': c.id, 'score': c.score})
            .toList(),
      };
}
