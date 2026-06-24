import 'package:speech_to_text/speech_to_text.dart';

/// Wraps `speech_to_text` for capturing the user's spoken reply on the call
/// screen, in the user's chosen language when the device supports it.
class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;

  Future<bool> ensureInitialised() async {
    if (_available) return true;
    _available = await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    return _available;
  }

  bool get isListening => _stt.isListening;

  /// Starts listening, reporting partial and final transcripts via [onResult].
  /// [localeTag] is a BCP-47 tag like 'hi-IN'; it's resolved against the
  /// device's installed recognisers (falls back to the default if unavailable).
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
    String? localeTag,
  }) async {
    if (!await ensureInitialised()) return;
    final localeId = await _resolveLocale(localeTag);
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        localeId: localeId,
      ),
    );
  }

  /// Finds an installed recogniser whose locale matches the language of
  /// [localeTag] (e.g. 'hi-IN' → first available 'hi_*'), or null for default.
  Future<String?> _resolveLocale(String? localeTag) async {
    if (localeTag == null) return null;
    final lang = localeTag.split(RegExp('[-_]')).first.toLowerCase();
    final locales = await _stt.locales();
    for (final l in locales) {
      if (l.localeId.toLowerCase().startsWith(lang)) return l.localeId;
    }
    return null;
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}
