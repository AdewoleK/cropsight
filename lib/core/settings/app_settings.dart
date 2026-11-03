import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/device_capability.dart';

/// The app's language: every screen, the AI's written answer, and the voice
/// used to read results aloud. Nigeria's three main languages plus Pidgin
/// and English; Hausa first, as most users are expected in the north.
///
/// [promptName] is what the model is told to write in; [ttsLocales] are the
/// voice locales tried in order when reading aloud — the phone may not have
/// a voice for every language, so later entries are fallbacks.
enum AnswerLanguage {
  hausa('Hausa', 'Hausa', ['ha-NG', 'ha']),
  yoruba('Yorùbá', 'Yoruba', ['yo-NG', 'yo']),
  igbo('Igbo', 'Igbo', ['ig-NG', 'ig']),
  pidgin('Naijá (Pidgin)', 'Nigerian Pidgin English', ['en-NG', 'en-GB', 'en-US']),
  english('English', 'English', ['en-NG', 'en-GB', 'en-US']);

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
  static const _shareReportsKey = 'share_reports';
  static const _languageChosenKey = 'language_chosen';
  static const _stateKey = 'report_state_pcode';
  static const _lgaKey = 'report_lga_pcode';

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
    _prefs.setBool(_languageChosenKey, true);
    notifyListeners();
  }

  /// Whether the farmer has picked a language yet. Until then the app opens
  /// on the language screen, before anything else.
  bool get languageChosen => _prefs.getBool(_languageChosenKey) ?? false;

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

  /// Farmer's consent to send anonymised results (no photo, no text) to
  /// plant-health officers for outbreak watching. Off until they turn it on.
  bool get shareReports => _prefs.getBool(_shareReportsKey) ?? false;

  set shareReports(bool value) {
    _prefs.setBool(_shareReportsKey, value);
    notifyListeners();
  }

  /// Where the farmer farms, as OCHA P-codes. Picked by hand, never from GPS,
  /// so no exact location is ever recorded.
  String? get reportStatePcode => _prefs.getString(_stateKey);
  String? get reportLgaPcode => _prefs.getString(_lgaKey);

  void setReportRegion({required String statePcode, String? lgaPcode}) {
    _prefs.setString(_stateKey, statePcode);
    if (lgaPcode == null) {
      _prefs.remove(_lgaKey);
    } else {
      _prefs.setString(_lgaKey, lgaPcode);
    }
    notifyListeners();
  }
}
