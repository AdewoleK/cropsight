import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai/device_capability.dart';
import '../../core/settings/app_settings.dart';
import '../../core/speech/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';

/// App-bar gear that opens [SettingsScreen] — shown on every tab.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Settings',
      icon: const Icon(Icons.tune),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}

/// Theme, answer language and voice. No account section, because there is
/// no account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// A short phrase per language for "Test voice".
  static const _samples = {
    AnswerLanguage.english: 'Hello. This is how CropSight will read your results.',
    AnswerLanguage.french: 'Bonjour. Voici comment CropSight lira vos résultats.',
    AnswerLanguage.portuguese: 'Olá. É assim que o CropSight vai ler os seus resultados.',
    AnswerLanguage.swahili: 'Habari. Hivi ndivyo CropSight itakavyosoma matokeo yako.',
    AnswerLanguage.hausa: 'Sannu. Haka CropSight zai karanta sakamakon ka.',
    AnswerLanguage.yoruba: 'Ẹ n lẹ. Báyìí ni CropSight yóò ṣe ka èsì yín.',
    AnswerLanguage.igbo: 'Ndewo. Otu a ka CropSight ga-esi gụọ nsonaazụ gị.',
    AnswerLanguage.pidgin: 'How far. Na so CropSight go take read your result.',
    AnswerLanguage.amharic: 'ሰላም። CropSight ውጤቶችዎን እንዲህ ያነባል።',
    AnswerLanguage.zulu: 'Sawubona. Yile ndlela iCropSight ezofunda ngayo imiphumela yakho.',
  };

  static String _modeHelp(AppSettings settings) {
    final ram = DeviceCapability.ramMb;
    final ramText = ram == null
        ? 'This phone\'s memory could not be read.'
        : 'This phone has ${(ram / 1024).toStringAsFixed(1)} GB of memory.';
    return '$ramText Photo mode reads a picture with on-device AI and needs '
        'about 6 GB. Lite mode works on any phone: you tap what you see and '
        'it matches the field guide. Automatic picks for you — now using '
        '${settings.useLiteMode ? 'Lite' : 'Photo'}.';
  }

  Future<void> _testVoice(BuildContext context, AnswerLanguage language) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await SpeechService.instance.speak(_samples[language]!, language);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text('This phone has no ${language.promptName} voice. Results '
            'will still be written in ${language.promptName}.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTheme.stencil(size: 19, color: p.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionLabel('Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.phone_iphone, size: 16),
                  label: Text('Phone')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 16),
                  label: Text('Light')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                  label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => settings.themeMode = s.first,
          ),
          const SizedBox(height: 6),
          Text('"Phone" follows your phone\'s light/dark setting.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          const SectionLabel('Diagnosis mode'),
          SegmentedButton<DiagnosisMode>(
            segments: [
              for (final mode in DiagnosisMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {settings.diagnosisMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => settings.diagnosisMode = s.first,
          ),
          const SizedBox(height: 6),
          Text(_modeHelp(settings), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          const SectionLabel('Answer language'),
          Text(
            'Diagnoses are written in this language. Small on-device models '
            'write some languages better than others — if an answer reads '
            'oddly, try English or French.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          RadioGroup<AnswerLanguage>(
            groupValue: settings.language,
            onChanged: (l) {
              if (l != null) settings.language = l;
            },
            child: Column(
              children: [
                for (final language in AnswerLanguage.values)
                  RadioListTile<AnswerLanguage>(
                    value: language,
                    contentPadding: EdgeInsets.zero,
                    title: Text(language.nativeName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: language.nativeName == language.promptName
                        ? null
                        : Text(language.promptName),
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _testVoice(context, settings.language),
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            label: const Text('Test voice'),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Privacy'),
          Text(
            'No account, no sign-in. Photos, fields and reminders stay on this '
            'phone. The AI runs on the phone and works with no internet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
