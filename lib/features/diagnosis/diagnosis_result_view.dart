import 'package:flutter/material.dart';

import '../../core/rag/local_vector_index.dart';
import '../../theme/widgets.dart';
import '../library/card_detail_screen.dart';
import 'structured_diagnosis.dart';

/// Renders a completed diagnosis as distinct, stamped sections (crop,
/// confidence, steps, sources) when [StructuredDiagnosis.tryParse] succeeds,
/// falling back to the raw model text otherwise — small on-device models
/// don't always follow the requested format exactly.
class DiagnosisResultView extends StatelessWidget {
  const DiagnosisResultView({
    super.key,
    required this.answer,
    required this.structured,
    this.sources = const [],
  });

  final String answer;
  final StructuredDiagnosis? structured;
  final List<RetrievedCard> sources;

  @override
  Widget build(BuildContext context) {
    final s = structured;
    if (s == null) {
      return SelectableText(answer, style: Theme.of(context).textTheme.bodyLarge);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.crop != null || s.problem != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s.crop != null) StampTag(label: s.crop!, filled: true),
              if (s.problem != null) StampTag(label: s.problem!),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (s.confidenceLevel != null) ...[
          ConfidenceWord(level: s.confidenceLevel!, reason: s.confidenceReason),
        ],
        if (s.steps.isNotEmpty) ...[
          const SectionLabel('What to do now'),
          const SizedBox(height: 4),
          StepTimeline(steps: s.steps),
        ],
        // Safety for the best-matching card's treatments, so it's on screen
        // before anyone reaches for a sprayer.
        if (sources.isNotEmpty && sources.first.card.safety != null) ...[
          SafetyNote(title: 'Before you spray', text: sources.first.card.safety!),
          const SizedBox(height: 14),
        ],
        if (sources.isNotEmpty) ...[
          const SectionLabel('Sources — tap to read more'),
          for (final source in sources)
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CardDetailScreen(card: source.card),
              )),
              child: LedgerRow(
                label: source.card.label,
                value: '${(source.score * 100).round()}%',
              ),
            ),
        ],
      ],
    );
  }
}
