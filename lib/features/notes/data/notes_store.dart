import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// Persists notes on-device via [SharedPreferences] as a JSON list.
class NotesStore {
  NotesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _listKey = 'notes.list';
  static const String _seqKey = 'notes.seq';

  List<Note> getAll() {
    final raw = _prefs.getString(_listKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Note> notes) async {
    await _prefs.setString(
      _listKey,
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
  }

  int nextId() {
    final next = (_prefs.getInt(_seqKey) ?? 0) + 1;
    _prefs.setInt(_seqKey, next);
    return next;
  }
}
