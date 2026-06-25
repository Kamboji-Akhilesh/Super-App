import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notes_store.dart';
import '../models/note.dart';
import '../providers.dart';

/// Owns the list of notes and persists every mutation.
///
/// State is kept sorted for display: pinned notes first, then by most-recently
/// updated, so the grid and any watchers render in a stable order.
class NotesController extends Notifier<List<Note>> {
  late final NotesStore _store = ref.read(notesStoreProvider);

  @override
  List<Note> build() => _sorted(_store.getAll());

  Note? byId(int id) {
    for (final n in state) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Creates a note and returns it. Blank notes are not persisted.
  Future<Note?> create({
    String title = '',
    String body = '',
    int colorId = 0,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _store.nextId(),
      title: title,
      body: body,
      colorId: colorId,
      createdAt: now,
      updatedAt: now,
    );
    if (note.isEmpty) return null;
    state = _sorted([...state, note]);
    await _persist();
    return note;
  }

  Future<void> update(
    int id, {
    String? title,
    String? body,
    int? colorId,
  }) async {
    final existing = byId(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      title: title,
      body: body,
      colorId: colorId,
      updatedAt: DateTime.now(),
    );
    // An edit that empties a note removes it.
    if (updated.isEmpty) {
      await delete(id);
      return;
    }
    state = _sorted(_replace(updated));
    await _persist();
  }

  Future<void> togglePin(int id) async {
    final n = byId(id);
    if (n == null) return;
    state = _sorted(_replace(n.copyWith(pinned: !n.pinned)));
    await _persist();
  }

  Future<void> setColor(int id, int colorId) async {
    final n = byId(id);
    if (n == null) return;
    state = _sorted(_replace(n.copyWith(colorId: colorId)));
    await _persist();
  }

  Future<void> delete(int id) async {
    state = state.where((n) => n.id != id).toList();
    await _persist();
  }

  /// Re-inserts a previously deleted note (used for undo) at its original spot
  /// in the sort order.
  Future<void> restore(Note note) async {
    if (byId(note.id) != null) return;
    state = _sorted([...state, note]);
    await _persist();
  }

  // --- internals ------------------------------------------------------------

  Future<void> _persist() => _store.saveAll(state);

  List<Note> _replace(Note updated) => [
        for (final n in state)
          if (n.id == updated.id) updated else n,
      ];

  static List<Note> _sorted(List<Note> notes) {
    final list = [...notes]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }
}
