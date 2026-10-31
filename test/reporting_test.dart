import 'package:cropsight/core/rag/knowledge_base.dart';
import 'package:cropsight/core/rag/local_vector_index.dart';
import 'package:cropsight/core/sync/diagnosis_result.dart';
import 'package:cropsight/features/diagnosis/diagnosis_controller.dart';
import 'package:flutter_test/flutter_test.dart';

DiagnosisResult _result() => DiagnosisResult(
      id: '1',
      timestamp: DateTime.utc(2026, 10, 31, 9),
      description: 'Pale papery mines on tomato leaves near Ikara market',
      answer: 'CROP: tomato\nPROBLEM: Tuta absoluta',
      citedCards: const [
        CitedCard(id: 'tomato_tuta_absoluta', label: 'Tomato: Tuta', score: 0.88),
      ],
      source: DiagnosisSource.photo,
      confidence: 'high',
    );

void main() {
  test('nothing is reportable without consent', () {
    final r = _result().withReporting(
        shared: false, statePcode: 'NG019', lgaPcode: 'NG019005');
    expect(r.reportable, isFalse);
  });

  test('nothing is reportable without an LGA', () {
    final r = _result().withReporting(shared: true, statePcode: 'NG019');
    expect(r.reportable, isFalse);
  });

  test('consent plus an LGA makes it reportable', () {
    final r = _result().withReporting(
        shared: true, statePcode: 'NG019', lgaPcode: 'NG019005');
    expect(r.reportable, isTrue);
  });

  test('payload carries the LGA and card, never the farmer\'s words', () {
    final payload = _result()
        .withReporting(shared: true, statePcode: 'NG019', lgaPcode: 'NG019005')
        .toSyncPayload('anon');
    expect(payload['lga_pcode'], 'NG019005');
    expect(payload['confidence'], 'high');
    expect(payload['source'], 'photo');
    expect(payload['cited_cards'], [
      {'id': 'tomato_tuta_absoluta', 'score': 0.88},
    ]);
    final text = payload.toString();
    expect(text, isNot(contains('Ikara market')));
    expect(text, isNot(contains('PROBLEM')));
    expect(payload.keys, isNot(contains('description')));
    expect(payload.keys, isNot(contains('answer')));
  });

  test('older saved results without reporting fields still load', () {
    final legacy = {
      'id': '1',
      'timestamp': '2026-10-01T10:00:00.000',
      'description': 'd',
      'answer': 'a',
      'citedCards': [],
      'synced': false,
    };
    final r = DiagnosisResult.fromLocalJson(legacy);
    expect(r.reportable, isFalse);
    expect(r.source, DiagnosisSource.photo);
  });

  test('local record round-trips the reporting fields', () {
    final r = _result().withReporting(
        shared: true, statePcode: 'NG019', lgaPcode: 'NG019005');
    final back = DiagnosisResult.fromLocalJson(r.toLocalJson());
    expect(back.lgaPcode, 'NG019005');
    expect(back.shared, isTrue);
    expect(back.confidence, 'high');
  });

  group('reported card follows what the model cited', () {
    RetrievedCard hit(String id, double s) => RetrievedCard(
        KnowledgeBase.cards.firstWhere((c) => c.id == id), s);
    final retrieved = [
      hit('tomato_late_blight', 0.9),
      hit('tomato_tuta_absoluta', 0.85),
    ];

    test('picks the cited card, not the top hit', () {
      final out = DiagnosisController.reportedCards(
          retrieved, 'Tomato leafminer (Tuta absoluta)');
      expect(out.map((r) => r.card.id), ['tomato_tuta_absoluta']);
    });

    test('nothing cited gives nothing', () {
      expect(DiagnosisController.reportedCards(retrieved, null), isEmpty);
      expect(DiagnosisController.reportedCards(retrieved, 'none'), isEmpty);
    });
  });
}
