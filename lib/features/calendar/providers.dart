import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'controllers/calendar_controller.dart';
import 'data/calendar_store.dart';
import 'models/calendar_entry.dart';

final calendarStoreProvider = Provider<CalendarStore>(
  (ref) => CalendarStore(ref.watch(sharedPreferencesProvider)),
);

final calendarControllerProvider =
    NotifierProvider<CalendarController, List<CalendarEntry>>(
  CalendarController.new,
);
