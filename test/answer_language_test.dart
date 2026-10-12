import 'package:cropsight/core/settings/app_settings.dart';
import 'package:cropsight/features/diagnosis/diagnosis_controller.dart';
import 'package:cropsight/features/diagnosis/structured_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English uses the base instruction with no language line', () {
    final prompt = DiagnosisController.systemInstructionFor(AnswerLanguage.english);
    expect(prompt, isNot(contains('Write every value in')));
  });

  test('other languages translate values but keep English labels', () {
    final prompt = DiagnosisController.systemInstructionFor(AnswerLanguage.hausa);
    expect(prompt, contains('Write every value in Hausa'));
    expect(prompt, contains('Keep the labels CROP, PROBLEM'));
    expect(prompt, contains('CONFIDENCE value as the English word'));
  });

  test('a Swahili answer with English labels still parses', () {
    const answer = '''
CROP: Muhogo
PROBLEM: Ugonjwa wa batobato
CONFIDENCE: medium
WHY: Majani yana rangi ya njano na kijani.
STEPS:
- Ng'oa mimea iliyoathirika na uichome.
- Panda vipandikizi visivyo na ugonjwa.
SOURCES: Cassava: Cassava mosaic disease
''';
    final parsed = StructuredDiagnosis.tryParse(answer)!;
    expect(parsed.crop, 'Muhogo');
    expect(parsed.confidenceLevel, 'medium');
    expect(parsed.steps, hasLength(2));
  });
}
