import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around `flutter_tts` for speaking the reminder prompt aloud
/// on the call screen, in the user's chosen language.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  String? _appliedLocale;

  Future<void> _configure(String? locale) async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1);
    await _tts.awaitSpeakCompletion(true);
    if (locale != null && locale != _appliedLocale) {
      // Only switch if the device actually has the voice, else keep default.
      final available = await _tts.isLanguageAvailable(locale);
      if (available == true) {
        await _tts.setLanguage(locale);
        _appliedLocale = locale;
      }
    }
  }

  /// Speaks [text]. [locale] is a BCP-47 tag like 'hi-IN'.
  Future<void> speak(String text, {String? locale}) async {
    await _configure(locale);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  void dispose() => _tts.stop();
}
