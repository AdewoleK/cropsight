import 'package:flutter/widgets.dart';

import '../core/settings/app_settings.dart';
import 'translations_ha.dart';
import 'translations_ig.dart';
import 'translations_pcm.dart';
import 'translations_yo.dart';

/// The app's on-screen text in the farmer's language.
///
/// The English text is the key: `context.tr('Find matches')`. Each language
/// has a map from English to its own wording (translations_*.dart). Anything
/// missing falls back to English rather than showing nothing, and
/// test/l10n_test.dart fails if any language lacks a phrase used in lib/.
///
/// Placeholders are written {name}: `context.tr('{n} farmers', {'n': 3})`.
///
/// These translations are drafts to be checked by native speakers who know
/// farming (e.g. state ADP extension officers) before wide use.
const Map<AnswerLanguage, Map<String, String>> translations = {
  AnswerLanguage.hausa: hausa,
  AnswerLanguage.yoruba: yoruba,
  AnswerLanguage.igbo: igbo,
  AnswerLanguage.pidgin: pidgin,
};

/// Translate [english] into [language], filling {placeholders} from [args].
String translate(AnswerLanguage language, String english, [Map<String, Object?> args = const {}]) {
  var text = translations[language]?[english] ?? english;
  args.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
  return text;
}

/// Language for code with no BuildContext (notifications, share text built
/// in services). Kept in step with [AppSettings.language] by [LanguageScope].
AnswerLanguage currentLanguage = AnswerLanguage.english;

/// Translate outside widgets, in the current app language.
String tr(String english, [Map<String, Object?> args = const {}]) =>
    translate(currentLanguage, english, args);

/// Puts the app language above every route, so widgets that call
/// [BuildContextTr.tr] rebuild when it changes.
class LanguageScope extends InheritedWidget {
  LanguageScope({super.key, required this.language, required super.child}) {
    currentLanguage = language;
  }

  final AnswerLanguage language;

  static AnswerLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.language ??
      currentLanguage;

  @override
  bool updateShouldNotify(LanguageScope old) => old.language != language;
}

extension BuildContextTr on BuildContext {
  /// Translate [english] into the app language. In build methods this also
  /// makes the widget rebuild when the language changes.
  String tr(String english, [Map<String, Object?> args = const {}]) =>
      translate(LanguageScope.of(this), english, args);
}
