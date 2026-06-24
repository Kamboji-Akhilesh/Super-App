import 'package:flutter/foundation.dart';

/// A language the reminder voice (TTS), speech recognition (STT) and call-screen
/// text can use.
@immutable
class VoiceLanguage {
  const VoiceLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.ttsLocale,
  });

  /// Short language code, e.g. 'hi'. Matches the keys in `ReminderStrings`.
  final String code;
  final String nativeName;
  final String englishName;

  /// BCP-47 locale used for TTS, e.g. 'hi-IN'. The STT locale is derived from
  /// this (resolved against the device's available recognisers at runtime).
  final String ttsLocale;

  String get label => englishName == nativeName
      ? englishName
      : '$englishName ($nativeName)';

  /// Supported voice languages — English plus major Indian languages. Each has
  /// a matching translation set in `ReminderStrings`.
  static const List<VoiceLanguage> supported = [
    VoiceLanguage(
        code: 'en', nativeName: 'English', englishName: 'English', ttsLocale: 'en-US'),
    VoiceLanguage(
        code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', ttsLocale: 'hi-IN'),
    VoiceLanguage(
        code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali', ttsLocale: 'bn-IN'),
    VoiceLanguage(
        code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil', ttsLocale: 'ta-IN'),
    VoiceLanguage(
        code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu', ttsLocale: 'te-IN'),
    VoiceLanguage(
        code: 'mr', nativeName: 'मराठी', englishName: 'Marathi', ttsLocale: 'mr-IN'),
    VoiceLanguage(
        code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada', ttsLocale: 'kn-IN'),
    VoiceLanguage(
        code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati', ttsLocale: 'gu-IN'),
  ];

  static VoiceLanguage byCode(String code) => supported.firstWhere(
        (l) => l.code == code,
        orElse: () => supported.first,
      );
}
