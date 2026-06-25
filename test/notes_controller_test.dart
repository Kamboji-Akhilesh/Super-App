import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/providers.dart';
import 'package:super_app/features/notes/controllers/notes_controller.dart';
import 'package:super_app/features/notes/models/note.dart';
import 'package:super_app/features/notes/providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  NotesController c() => container.read(notesControllerProvider.notifier);
  List<Note> notes() => container.read(notesControllerProvider);

  test('creates a note and persists it', () async {
    final created = await c().create(title: 'Groceries', body: 'milk, eggs');
    expect(created, isNotNull);
    expect(notes(), hasLength(1));
    expect(notes().first.title, 'Groceries');
  });

  test('blank notes are not created', () async {
    final created = await c().create(title: '   ', body: '\n');
    expect(created, isNull);
    expect(notes(), isEmpty);
  });

  test('emptying a note via update deletes it', () async {
    final note = await c().create(body: 'temp');
    await c().update(note!.id, title: '', body: '');
    expect(notes(), isEmpty);
  });

  test('pinned notes sort before others, newest-updated first', () async {
    final a = await c().create(body: 'a');
    await c().create(body: 'b');
    final cNote = await c().create(body: 'c');
    await c().togglePin(a!.id);

    final ordered = notes();
    expect(ordered.first.id, a.id, reason: 'pinned first');
    // Among unpinned, the most recently created (c) precedes b.
    expect(ordered[1].id, cNote!.id);
  });

  test('delete then restore brings the note back', () async {
    final note = await c().create(title: 'keep me', body: 'x');
    await c().delete(note!.id);
    expect(notes(), isEmpty);
    await c().restore(note);
    expect(notes(), hasLength(1));
    expect(notes().first.title, 'keep me');
  });

  test('notes survive a controller rebuild (persistence)', () async {
    await c().create(title: 'persisted', body: 'y');
    container.invalidate(notesControllerProvider);
    expect(notes(), hasLength(1));
    expect(notes().first.title, 'persisted');
  });
}
