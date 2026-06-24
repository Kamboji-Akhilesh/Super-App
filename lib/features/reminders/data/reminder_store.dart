import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';
import '../models/reminder_settings.dart';

/// Persists reminders and settings on-device via [SharedPreferences].
class ReminderStore {
  ReminderStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _listKey = 'reminders.list';
  static const String _settingsKey = 'reminders.settings';
  static const String _seqKey = 'reminders.seq';

  List<Reminder> getAll() {
    final raw = _prefs.getString(_listKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Reminder> reminders) async {
    final raw = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await _prefs.setString(_listKey, raw);
  }

  /// Returns a fresh, monotonically increasing id (also used as the
  /// notification id, so it must stay unique and stable).
  int nextId() {
    final next = (_prefs.getInt(_seqKey) ?? 0) + 1;
    _prefs.setInt(_seqKey, next);
    return next;
  }

  ReminderSettings getSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const ReminderSettings();
    return ReminderSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }
}
