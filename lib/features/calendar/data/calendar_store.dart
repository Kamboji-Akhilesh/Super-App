import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_entry.dart';

/// Persists calendar entries on-device via [SharedPreferences].
class CalendarStore {
  CalendarStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _listKey = 'calendar.entries';
  static const String _seqKey = 'calendar.seq';

  List<CalendarEntry> getAll() {
    final raw = _prefs.getString(_listKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<CalendarEntry> entries) async {
    await _prefs.setString(
      _listKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  int nextId() {
    final next = (_prefs.getInt(_seqKey) ?? 0) + 1;
    _prefs.setInt(_seqKey, next);
    return next;
  }
}
