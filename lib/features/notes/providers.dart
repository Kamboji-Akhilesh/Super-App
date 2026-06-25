import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'controllers/notes_controller.dart';
import 'data/notes_store.dart';
import 'models/note.dart';

final notesStoreProvider = Provider<NotesStore>(
  (ref) => NotesStore(ref.watch(sharedPreferencesProvider)),
);

final notesControllerProvider =
    NotifierProvider<NotesController, List<Note>>(NotesController.new);
