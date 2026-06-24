import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_settings.dart';
import '../providers.dart';

class ReminderSettingsController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() => ref.watch(reminderStoreProvider).getSettings();

  Future<void> setDefaultMinutes(int minutes) async {
    state = state.copyWith(defaultConfirmationMinutes: minutes);
    await ref.read(reminderStoreProvider).saveSettings(state);
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    state = state.copyWith(voiceEnabled: enabled);
    await ref.read(reminderStoreProvider).saveSettings(state);
  }

  Future<void> setMaxConfirmations(int max) async {
    state = state.copyWith(maxConfirmations: max);
    await ref.read(reminderStoreProvider).saveSettings(state);
  }

  Future<void> setLanguage(String code) async {
    state = state.copyWith(languageCode: code);
    await ref.read(reminderStoreProvider).saveSettings(state);
  }

  Future<void> setRingtoneEnabled(bool enabled) async {
    state = state.copyWith(ringtoneEnabled: enabled);
    await ref.read(reminderStoreProvider).saveSettings(state);
  }
}
