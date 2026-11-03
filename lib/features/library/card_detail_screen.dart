import 'package:flutter/material.dart';

import '../../core/rag/knowledge_card.dart';
import '../../core/settings/app_settings.dart';
import '../../core/speech/speech_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/widgets.dart';

/// One reference card in full: what it looks like, what to do, and how to
/// stay safe doing it.
class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.card});
  final KnowledgeCard card;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          // Cards are written in English, so they're read in English
          // whatever the answer-language setting is.
          ListenableBuilder(
            listenable: SpeechService.instance,
            builder: (context, _) {
              final speaking = SpeechService.instance.isSpeaking;
              return IconButton(
                tooltip: speaking ? context.tr('Stop reading') : context.tr('Read aloud'),
                icon: Icon(speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
                onPressed: () => speaking
                    ? SpeechService.instance.stop()
                    : SpeechService.instance.speak(
                        '${card.title}. ${card.symptoms} What to do: ${card.management}'
                        '${card.safety == null ? '' : ' Safety: ${card.safety}'}',
                        AnswerLanguage.english,
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Wrap(
            spacing: 8,
            children: [
              StampTag(label: context.tr(card.crop), filled: true),
              StampTag(label: context.tr(card.kind.label)),
            ],
          ),
          const SizedBox(height: 14),
          Text(context.tr(card.title), style: text.headlineSmall),
          const SizedBox(height: 8),
          const EnglishOnlyNote(),
          SectionLabel(context.tr('What you see')),
          Text(card.symptoms, style: text.bodyLarge),
          const SizedBox(height: 12),
          SectionLabel(context.tr('What to do')),
          Text(card.management, style: text.bodyLarge),
          if (card.safety != null) ...[
            const SizedBox(height: 16),
            SafetyNote(text: card.safety!),
          ],
          const SizedBox(height: 20),
          Text(
            context.tr('General guidance. For serious or spreading problems, contact your local extension officer.'),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
