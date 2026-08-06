/// A diagnosis parsed from the model's labeled-line answer format (see
/// `DiagnosisController._systemInstruction`) into fields the UI can render as
/// distinct cards instead of one block of text.
///
/// On-device small models don't always follow a requested format exactly, so
/// [tryParse] is deliberately forgiving: it returns whatever fields it can
/// find, or null if it found essentially nothing usable — callers should fall
/// back to showing the raw text in that case.
class StructuredDiagnosis {
  const StructuredDiagnosis({
    this.crop,
    this.problem,
    this.confidenceLevel,
    this.confidenceReason,
    this.steps = const [],
    this.sourcesText,
  });

  final String? crop;
  final String? problem;

  /// Normalized to 'low' / 'medium' / 'high', or null if missing/unrecognized.
  final String? confidenceLevel;
  final String? confidenceReason;
  final List<String> steps;
  final String? sourcesText;

  static const _levels = {'low', 'medium', 'high'};

  static StructuredDiagnosis? tryParse(String text) {
    String? crop, problem, confidenceLevel, confidenceReason, sourcesText;
    final steps = <String>[];
    var inSteps = false;

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (_isLabel(line, 'STEPS')) {
        inSteps = true;
        continue;
      }
      final field = _field(line, 'CROP');
      if (field != null) {
        crop = field;
        inSteps = false;
        continue;
      }
      final problemField = _field(line, 'PROBLEM');
      if (problemField != null) {
        problem = problemField;
        inSteps = false;
        continue;
      }
      final confidenceField = _field(line, 'CONFIDENCE');
      if (confidenceField != null) {
        final level = confidenceField.toLowerCase().trim();
        confidenceLevel = _levels.contains(level) ? level : null;
        inSteps = false;
        continue;
      }
      final whyField = _field(line, 'WHY');
      if (whyField != null) {
        confidenceReason = whyField;
        inSteps = false;
        continue;
      }
      final sourcesField = _field(line, 'SOURCES');
      if (sourcesField != null) {
        sourcesText = sourcesField;
        inSteps = false;
        continue;
      }
      if (inSteps) {
        final step = line.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim();
        if (step.isNotEmpty) steps.add(step);
      }
    }

    if (crop == null && problem == null && steps.isEmpty) return null;

    return StructuredDiagnosis(
      crop: crop,
      problem: problem,
      confidenceLevel: confidenceLevel,
      confidenceReason: confidenceReason,
      steps: steps,
      sourcesText: sourcesText,
    );
  }

  /// Whether [line] is a bare "LABEL" or "LABEL:" header line (case-insensitive).
  static bool _isLabel(String line, String label) =>
      RegExp('^$label\\s*:?\$', caseSensitive: false).hasMatch(line);

  /// Matches a "LABEL: value" line (case-insensitive) with a non-empty value.
  static String? _field(String line, String label) {
    final match = RegExp('^$label\\s*:\\s*(.*)\$', caseSensitive: false)
        .firstMatch(line);
    final value = match?.group(1)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }
}
