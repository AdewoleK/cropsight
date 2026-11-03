import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/app_settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/widgets.dart';

/// The very first screen: pick a language. Everything on it is written in
/// each language itself, so a farmer who reads no English can still choose.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// "Choose your language" in each language, shown together as the heading.
  static const _headings = [
    'Zaɓi harshenka',
    'Yan èdè rẹ',
    'Họrọ asụsụ gị',
    'Pick your language',
  ];

  /// A short line under each option, in that option's own language.
  static const _subtitles = {
    AnswerLanguage.hausa: 'Yi amfani da Hausa',
    AnswerLanguage.yoruba: 'Lo èdè Yorùbá',
    AnswerLanguage.igbo: 'Jiri asụsụ Igbo',
    AnswerLanguage.pidgin: 'Use Pidgin',
    AnswerLanguage.english: 'Use English',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            const Center(child: CropSightMark(size: 64)),
            const SizedBox(height: 14),
            Text('CropSight',
                textAlign: TextAlign.center,
                style: AppTheme.stencil(size: 28, color: p.ink)),
            const SizedBox(height: 14),
            for (final h in _headings)
              Text(h,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: p.inkSoft)),
            const SizedBox(height: 22),
            for (final language in AnswerLanguage.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: p.paper2,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => context.read<AppSettings>().language = language,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.nativeName,
                                    style: TextStyle(
                                        fontSize: 22, fontWeight: FontWeight.w800, color: p.ink)),
                                const SizedBox(height: 2),
                                Text(_subtitles[language]!,
                                    style: TextStyle(fontSize: 14, color: p.inkSoft)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward, color: p.rust),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
