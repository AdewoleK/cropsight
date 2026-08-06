import 'package:flutter/material.dart';

import 'structured_diagnosis.dart';

/// Renders a completed diagnosis as distinct cards (crop, confidence, steps,
/// sources) when [StructuredDiagnosis.tryParse] succeeds, falling back to the
/// raw model text otherwise — small on-device models don't always follow the
/// requested format exactly.
class DiagnosisResultView extends StatelessWidget {
  const DiagnosisResultView({
    super.key,
    required this.answer,
    required this.structured,
  });

  final String answer;
  final StructuredDiagnosis? structured;

  @override
  Widget build(BuildContext context) {
    final s = structured;
    if (s == null) {
      return SelectableText(answer, style: Theme.of(context).textTheme.bodyLarge);
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.crop != null || s.problem != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s.crop != null) Chip(label: Text(s.crop!)),
              if (s.problem != null)
                Chip(
                  label: Text(s.problem!),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (s.confidenceLevel != null) ...[
          _ConfidenceBadge(level: s.confidenceLevel!, reason: s.confidenceReason),
          const SizedBox(height: 16),
        ],
        if (s.steps.isNotEmpty) ...[
          Text('What to do now', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          for (var i = 0; i < s.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12, color: theme.colorScheme.onPrimary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.steps[i])),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.level, this.reason});
  final String level;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (level) {
      'high' => (Colors.green, Icons.check_circle),
      'medium' => (Colors.orange, Icons.info),
      _ => (Colors.red, Icons.help),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
              children: [
                TextSpan(
                  text: '${level[0].toUpperCase()}${level.substring(1)} confidence',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                if (reason != null) TextSpan(text: ' — $reason'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
