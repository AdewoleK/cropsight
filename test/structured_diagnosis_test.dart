import 'package:flutter_test/flutter_test.dart';

import 'package:cropsight/features/diagnosis/structured_diagnosis.dart';

void main() {
  group('StructuredDiagnosis.tryParse', () {
    test('parses a well-formed answer', () {
      const answer = '''
CROP: Tomato
PROBLEM: Early blight
CONFIDENCE: medium
WHY: Leaf spots match the pattern but lighting is poor
STEPS:
- Remove affected lower leaves
- Avoid overhead watering
- Apply a copper-based fungicide
SOURCES: Tomato early blight, Tomato late blight
''';
      final result = StructuredDiagnosis.tryParse(answer);
      expect(result, isNotNull);
      expect(result!.crop, 'Tomato');
      expect(result.problem, 'Early blight');
      expect(result.confidenceLevel, 'medium');
      expect(result.confidenceReason,
          'Leaf spots match the pattern but lighting is poor');
      expect(result.steps, [
        'Remove affected lower leaves',
        'Avoid overhead watering',
        'Apply a copper-based fungicide',
      ]);
      expect(result.sourcesText, 'Tomato early blight, Tomato late blight');
    });

    test('is case-insensitive on labels and tolerant of bullet styles', () {
      const answer = '''
crop: Maize
problem: Leaf rust
confidence: HIGH
steps:
* First step
• Second step
- Third step
''';
      final result = StructuredDiagnosis.tryParse(answer);
      expect(result, isNotNull);
      expect(result!.crop, 'Maize');
      expect(result.confidenceLevel, 'high');
      expect(result.steps, ['First step', 'Second step', 'Third step']);
    });

    test('drops an unrecognized confidence value rather than guessing', () {
      const answer = '''
CROP: Rice
PROBLEM: Unclear
CONFIDENCE: not sure
STEPS:
- Take another photo in better light
''';
      final result = StructuredDiagnosis.tryParse(answer);
      expect(result, isNotNull);
      expect(result!.confidenceLevel, isNull);
    });

    test('returns null for free-form text with no recognizable fields', () {
      const answer = 'This does not look like a plant at all.';
      expect(StructuredDiagnosis.tryParse(answer), isNull);
    });
  });
}
