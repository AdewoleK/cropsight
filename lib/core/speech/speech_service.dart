import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../settings/app_settings.dart';

/// Reads text aloud using the phone's built-in voices, which work offline.
///
/// Not every phone has a voice for every language (Hausa, Yoruba, Igbo and
/// Amharic voices are often missing), so [speak] reports whether it could
/// find one instead of reading in the wrong accent silently.
class SpeechService extends ChangeNotifier {
  SpeechService._() {
    _tts.setCompletionHandler(_onStopped);
    _tts.setCancelHandler(_onStopped);
    _tts.setErrorHandler((_) => _onStopped());
  }
  static final SpeechService instance = SpeechService._();

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  void _onStopped() {
    if (!_speaking) return;
    _speaking = false;
    notifyListeners();
  }

  /// Speaks [text] in [language]. Returns false (and says nothing) when the
  /// phone has no voice for that language.
  Future<bool> speak(String text, AnswerLanguage language) async {
    await stop();
    final locale = await _voiceFor(language);
    if (locale == null) return false;
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.45);
    _speaking = true;
    notifyListeners();
    await _tts.speak(text);
    return true;
  }

  Future<void> stop() async {
    await _tts.stop();
    _onStopped();
  }

  Future<String?> _voiceFor(AnswerLanguage language) async {
    for (final locale in language.ttsLocales) {
      try {
        if (await _tts.isLanguageAvailable(locale) == true) return locale;
      } catch (_) {
        // Some engines throw for malformed/unknown locales — try the next.
      }
    }
    return null;
  }
}
