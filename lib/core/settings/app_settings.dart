import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/device_capability.dart';

/// A language the diagnosis can be written (and read aloud) in.
///
/// [promptName] is what the model is told to write in; [ttsLocales] are the
/// voice locales tried in order when reading aloud — the phone may not have
/// a voice for every language, so later entries are fallbacks.
enum AnswerLanguage {
  english('English', 'English', ['en-GB', 'en-US']),
  french('Français', 'French', ['fr-FR', 'fr-CA']),
  portuguese('Português', 'Portuguese', ['pt-PT', 'pt-BR']),
  swahili('Kiswahili', 'Swahili', ['sw-KE', 'sw-TZ', 'sw']),
  hausa('Hausa', 'Hausa', ['ha-NG', 'ha']),
  yoruba('Yorùbá', 'Yoruba', ['yo-NG', 'yo']),
  igbo('Igbo', 'Igbo', ['ig-NG', 'ig']),
  pidgin('Naijá (Pidgin)', 'Nigerian Pidgin English', ['en-NG', 'en-GB', 'en-US']),
  amharic('አማርኛ', 'Amharic', ['am-ET', 'am']),
  zulu('isiZulu', 'Zulu', ['zu-ZA', 'zu']);

  const AnswerLanguage(this.nativeName, this.promptName, this.ttsLocales);

  final String nativeName;
  final String promptName;
  final List<String> ttsLocales;
}

/// How the Diagnose tab works: from a photo (needs a 6GB-class phone), or
/// Lite — the farmer describes the symptoms and the app matches them against
/// the field guide, which works on low-memory phones.
enum DiagnosisMode {
  auto('Automatic'),
  photo('Photo'),
  lite('Lite');

  const DiagnosisMode(this.label);
  final String label;
}

/// User preferences, persisted on the phone. There are no accounts — this is
/// the only "profile" the app keeps.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs);

  static const _themeKey = 'theme_mode';
  static const _languageKey = 'answer_language';
  static const _modeKey = 'diagnosis_mode';
  static const _liteReadyKey = 'lite_setup_done';

  final SharedPreferences _prefs;

  static Future<AppSettings> load() async {
    return AppSettings._(await SharedPreferences.getInstance());
  }

  ThemeMode get themeMode => ThemeMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      );

  set themeMode(ThemeMode mode) {
    _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  AnswerLanguage get language => AnswerLanguage.values.firstWhere(
        (l) => l.name == _prefs.getString(_languageKey),
        orElse: () => AnswerLanguage.english,
      );

  set language(AnswerLanguage language) {
    _prefs.setString(_languageKey, language.name);
    notifyListeners();
  }

  DiagnosisMode get diagnosisMode => DiagnosisMode.values.firstWhere(
        (m) => m.name == _prefs.getString(_modeKey),
        orElse: () => DiagnosisMode.auto,
      );

  set diagnosisMode(DiagnosisMode mode) {
    _prefs.setString(_modeKey, mode.name);
    notifyListeners();
  }

  /// The mode actually in effect once "Automatic" is resolved for this phone.
  bool get useLiteMode => switch (diagnosisMode) {
        DiagnosisMode.lite => true,
        DiagnosisMode.photo => false,
        DiagnosisMode.auto => !DeviceCapability.supportsPhotoDiagnosis,
      };

  /// Whether Lite-mode setup (embedder + index, no photo model) has run.
  bool get liteReady => _prefs.getBool(_liteReadyKey) ?? false;

  set liteReady(bool value) {
    _prefs.setBool(_liteReadyKey, value);
    notifyListeners();
  }
}
