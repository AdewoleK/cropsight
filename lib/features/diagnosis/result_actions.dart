import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/fields/field_store.dart';
import '../../core/settings/app_settings.dart';
import '../../core/speech/speech_service.dart';
import '../../theme/app_theme.dart';
import '../fields/field_sheets.dart';

/// Everything [ResultActions] needs about one finished diagnosis, whether it
/// came from a photo or from Lite-mode symptom matching.
class ResultSummary {
  const ResultSummary({
    required this.spokenText,
    required this.shareText,
    required this.language,
    this.photo,
    this.crop,
    this.problem,
    this.confidence,
  });

  final String spokenText;
  final String shareText;
  final AnswerLanguage language;
  final Uint8List? photo;
  final String? crop;
  final String? problem;
  final String? confidence;
}

/// What a farmer can do with a finished diagnosis: hear it, keep it with a
/// field, set a follow-up, or send it to an extension officer.
class ResultActions extends StatelessWidget {
  const ResultActions({
    super.key,
    required this.summary,
    required this.savedToFieldId,
    required this.onSaved,
  });

  final ResultSummary summary;
  final String? savedToFieldId;
  final ValueChanged<String> onSaved;

  Future<void> _listen(BuildContext context) async {
    final speech = SpeechService.instance;
    if (speech.isSpeaking) return speech.stop();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await speech.speak(summary.spokenText, summary.language);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text('This phone has no ${summary.language.promptName} '
            'voice installed.'),
      ));
    }
  }

  Future<void> _save(BuildContext context) async {
    final field = await showPickFieldSheet(context, crop: summary.crop);
    if (field == null) return;
    await FieldStore.instance.addEntry(
      fieldId: field.id,
      photo: summary.photo,
      problem: summary.problem,
      confidence: summary.confidence,
    );
    onSaved(field.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${field.name}')),
      );
    }
  }

  Future<void> _remind(BuildContext context) async {
    final ok = await showAddReminderSheet(
      context,
      fieldId: savedToFieldId,
      initialTitle: summary.problem == null
          ? 'Re-check the crop'
          : 'Re-check for ${summary.problem}',
    );
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder set')),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final photo = summary.photo;
    await SharePlus.instance.share(ShareParams(
      text: summary.shareText,
      files: photo == null
          ? null
          : [XFile.fromData(photo, mimeType: 'image/jpeg', name: 'crop-photo.jpg')],
      // iPad needs an anchor for the share popover.
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final saved = savedToFieldId != null;
    return Row(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: SpeechService.instance,
            builder: (context, _) {
              final speaking = SpeechService.instance.isSpeaking;
              return _ActionButton(
                icon: speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                label: speaking ? 'Stop' : 'Listen',
                onTap: () => _listen(context),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: saved ? Icons.check : Icons.grass_outlined,
            label: saved ? 'Saved' : 'Save',
            onTap: saved ? null : () => _save(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.alarm_add_outlined,
            label: 'Remind',
            onTap: () => _remind(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Builder(
            builder: (context) => _ActionButton(
              icon: Icons.ios_share,
              label: 'Share',
              onTap: () => _share(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = onTap == null ? p.husk : p.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.hairline, width: 1.4),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

/// The disclaimer appended to every shared result.
const String shareFooter =
    'From CropSight — offline AI and field guide. Please confirm with your '
    'local extension officer before spraying.';
