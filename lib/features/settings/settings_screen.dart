import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ai/device_capability.dart';
import '../../core/reporting/region_catalog.dart';
import '../../core/settings/app_settings.dart';
import '../../core/speech/speech_service.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';

/// App-bar gear that opens [SettingsScreen] — shown on every tab.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr('Settings'),
      icon: const Icon(Icons.tune),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}

/// Language, theme, diagnosis mode and reporting. No account section,
/// because there is no account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// A short phrase per language for "Test voice", in that language.
  static const _samples = {
    AnswerLanguage.english: 'Hello. This is how CropSight will read your results.',
    AnswerLanguage.hausa: 'Sannu. Haka CropSight zai karanta sakamakon ka.',
    AnswerLanguage.yoruba: 'Ẹ n lẹ. Báyìí ni CropSight yóò ṣe ka èsì yín.',
    AnswerLanguage.igbo: 'Ndewo. Otu a ka CropSight ga-esi gụọ nsonaazụ gị.',
    AnswerLanguage.pidgin: 'How far. Na so CropSight go take read your result.',
  };

  static String _modeHelp(BuildContext context, AppSettings settings) {
    final ram = DeviceCapability.ramMb;
    final ramText = ram == null
        ? context.tr("This phone's memory could not be read.")
        : context.tr('This phone has {gb} GB of memory.',
            {'gb': (ram / 1024).toStringAsFixed(1)});
    final mode = context.tr(settings.useLiteMode ? 'Lite' : 'Photo');
    return '$ramText ${context.tr('Photo mode reads a picture with on-device AI and needs about 6 GB. Lite mode works on any phone: you tap what you see and it matches the field guide. Automatic picks for you — now using {mode}.', {'mode': mode})}';
  }

  Future<void> _testVoice(BuildContext context, AnswerLanguage language) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await SpeechService.instance.speak(_samples[language]!, language);
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(tr('This phone has no {language} voice. Results will still be written in {language}.',
            {'language': language.nativeName})),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Settings'), style: AppTheme.stencil(size: 19, color: p.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SectionLabel(context.tr('Language')),
          Text(
            context.tr('CropSight shows its screens, writes its answers and reads aloud in this language.'),
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
                  ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _testVoice(context, settings.language),
            icon: const Icon(Icons.volume_up_outlined, size: 18),
            label: Text(context.tr('Test voice')),
          ),
          const SizedBox(height: 20),
          SectionLabel(context.tr('Appearance')),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.phone_iphone, size: 16),
                  label: Text(context.tr('Phone'))),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined, size: 16),
                  label: Text(context.tr('Light'))),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined, size: 16),
                  label: Text(context.tr('Dark'))),
            ],
            selected: {settings.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => settings.themeMode = s.first,
          ),
          const SizedBox(height: 6),
          Text(context.tr('"Phone" follows your phone\'s light/dark setting.'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          SectionLabel(context.tr('Diagnosis mode')),
          SegmentedButton<DiagnosisMode>(
            segments: [
              for (final mode in DiagnosisMode.values)
                ButtonSegment(value: mode, label: Text(context.tr(mode.label))),
            ],
            selected: {settings.diagnosisMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => settings.diagnosisMode = s.first,
          ),
          const SizedBox(height: 6),
          Text(_modeHelp(context, settings), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          SectionLabel(context.tr('Disease reporting')),
          const _ReportingSection(),
          const SizedBox(height: 24),
          SectionLabel(context.tr('Privacy')),
          Text(
            context.tr('No account, no sign-in. Photos, fields and reminders stay on this phone. The AI runs on the phone and works with no internet. If you turn on disease reporting, only the name of the problem, how sure the app was, the date and your LGA are sent.'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Consent switch plus state and LGA pickers. Reports let plant-health
/// officers spot an outbreak early when several farmers in one area find the
/// same problem.
class _ReportingSection extends StatelessWidget {
  const _ReportingSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<RegionCatalog>(
      future: RegionCatalog.load(),
      builder: (context, snapshot) {
        final catalog = snapshot.data;
        final state = catalog?.state(settings.reportStatePcode);
        final lgaSet = state?.lgas
                .any((l) => l.pcode == settings.reportLgaPcode) ??
            false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr("Help plant-health officers spot outbreaks early. When several farmers in one area find the same problem, officers can warn farms nearby. Your photo and the written answer never leave this phone — only the problem's name, how sure the app was, the date and your LGA."),
              style: textTheme.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Share my results'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(context.tr('Anonymous. You can turn this off any time.')),
              value: settings.shareReports,
              onChanged: (v) => settings.shareReports = v,
            ),
            if (catalog != null) ...[
              DropdownButtonFormField<String>(
                initialValue: state?.pcode,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('State')),
                items: [
                  for (final s in catalog.states)
                    DropdownMenuItem(value: s.pcode, child: Text(s.name)),
                ],
                onChanged: (pcode) {
                  if (pcode != null) settings.setReportRegion(statePcode: pcode);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(state?.pcode),
                initialValue: lgaSet ? settings.reportLgaPcode : null,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: context.tr('Local government area (LGA)')),
                items: [
                  for (final l in state?.lgas ?? const <Lga>[])
                    DropdownMenuItem(value: l.pcode, child: Text(l.name)),
                ],
                onChanged: state == null
                    ? null
                    : (pcode) => settings.setReportRegion(
                        statePcode: state.pcode, lgaPcode: pcode),
              ),
              if (settings.shareReports && !lgaSet) ...[
                const SizedBox(height: 6),
                Text(context.tr('Pick your LGA so your results can be counted.'),
                    style: textTheme.bodySmall
                        ?.copyWith(color: context.palette.brick)),
              ],
            ],
          ],
        );
      },
    );
  }
}
