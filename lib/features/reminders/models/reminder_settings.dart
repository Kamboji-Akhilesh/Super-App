import 'package:flutter/foundation.dart';

/// User-configurable defaults for reminders.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.defaultConfirmationMinutes = 5,
    this.voiceEnabled = true,
    this.maxConfirmations = 3,
    this.languageCode = 'en',
    this.ringtoneEnabled = true,
  });

  /// Default follow-up interval applied to new reminders (step 7).
  final int defaultConfirmationMinutes;

  /// Whether the call screen speaks the prompt aloud.
  final bool voiceEnabled;

  /// How many times to re-call asking "did you do it?" before giving up,
  /// so a forgotten task doesn't ring forever.
  final int maxConfirmations;

  /// Language code (see [VoiceLanguage]) for the spoken prompt, the speech
  /// recogniser and the call-screen text.
  final String languageCode;

  /// Whether to ring a looping tone until the call is accepted.
  final bool ringtoneEnabled;

  /// Options offered in the UI for the confirmation interval.
  static const List<int> intervalChoices = [1, 5, 10, 15, 30, 60];

  /// Options offered in the UI for the retry cap.
  static const List<int> maxConfirmationChoices = [1, 2, 3, 5, 10];

  ReminderSettings copyWith({
    int? defaultConfirmationMinutes,
    bool? voiceEnabled,
    int? maxConfirmations,
    String? languageCode,
    bool? ringtoneEnabled,
  }) =>
      ReminderSettings(
        defaultConfirmationMinutes:
            defaultConfirmationMinutes ?? this.defaultConfirmationMinutes,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
        maxConfirmations: maxConfirmations ?? this.maxConfirmations,
        languageCode: languageCode ?? this.languageCode,
        ringtoneEnabled: ringtoneEnabled ?? this.ringtoneEnabled,
      );

  Map<String, dynamic> toJson() => {
        'defaultConfirmationMinutes': defaultConfirmationMinutes,
        'voiceEnabled': voiceEnabled,
        'maxConfirmations': maxConfirmations,
        'languageCode': languageCode,
        'ringtoneEnabled': ringtoneEnabled,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      ReminderSettings(
        defaultConfirmationMinutes:
            json['defaultConfirmationMinutes'] as int? ?? 5,
        voiceEnabled: json['voiceEnabled'] as bool? ?? true,
        maxConfirmations: json['maxConfirmations'] as int? ?? 3,
        languageCode: json['languageCode'] as String? ?? 'en',
        ringtoneEnabled: json['ringtoneEnabled'] as bool? ?? true,
      );
}
