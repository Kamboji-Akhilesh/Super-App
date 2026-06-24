import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/providers.dart';
import 'package:super_app/features/calendar/controllers/calendar_controller.dart';
import 'package:super_app/features/calendar/models/calendar_entry.dart';
import 'package:super_app/features/calendar/providers.dart';
import 'package:super_app/features/reminders/providers.dart';
import 'package:super_app/features/reminders/services/notification_service.dart';

class _FakeNotif extends NotificationService {
  final Set<int> calls = {};
  final Set<int> notifs = {};

  @override
  Future<void> init({required void Function(String) onSelect}) async {}
  @override
  Future<void> requestPermissions() async {}
  @override
  Future<void> scheduleCall({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
  }) async =>
      calls.add(id);
  @override
  Future<void> scheduleNotification({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
  }) async =>
      notifs.add(id);
  @override
  Future<void> cancel(int id) async {
    calls.remove(id);
    notifs.remove(id);
  }

  @override
  Future<String?> launchPayload() async => null;
}

void main() {
  late ProviderContainer container;
  late _FakeNotif notif;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    notif = _FakeNotif();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notif),
    ]);
  });

  tearDown(() => container.dispose());

  CalendarController c() => container.read(calendarControllerProvider.notifier);
  List<CalendarEntry> entries() => container.read(calendarControllerProvider);

  final future = DateTime.now().add(const Duration(days: 1));

  test('event with notification alert schedules a notification', () async {
    await c().create(
      type: EntryType.event,
      title: 'Standup',
      start: future,
      end: future.add(const Duration(minutes: 30)),
      alertStyle: AlertStyle.notification,
      alertLead: AlertLead.min10,
    );
    expect(entries(), hasLength(1));
    expect(notif.notifs, isNotEmpty);
    expect(notif.calls, isEmpty);
  });

  test('task with call alert schedules a call', () async {
    await c().create(
      type: EntryType.task,
      title: 'Pay bill',
      start: future,
      alertStyle: AlertStyle.call,
      alertLead: AlertLead.atTime,
    );
    expect(notif.calls, isNotEmpty);
  });

  test('no alert / past alert are not scheduled', () async {
    await c().create(
      type: EntryType.event,
      title: 'No alert',
      start: future,
      alertStyle: AlertStyle.none,
      alertLead: AlertLead.atTime,
    );
    await c().create(
      type: EntryType.task,
      title: 'In the past',
      start: DateTime.now().subtract(const Duration(hours: 1)),
      alertStyle: AlertStyle.notification,
      alertLead: AlertLead.atTime,
    );
    expect(notif.calls, isEmpty);
    expect(notif.notifs, isEmpty);
  });

  test('completing a task cancels its alert', () async {
    await c().create(
      type: EntryType.task,
      title: 'Do it',
      start: future,
      alertStyle: AlertStyle.notification,
      alertLead: AlertLead.atTime,
    );
    final id = entries().single.id;
    expect(notif.notifs, isNotEmpty);
    await c().toggleDone(id);
    expect(notif.notifs, isEmpty);
  });

  test('entriesForDay filters and sorts by time', () async {
    final day = DateTime(future.year, future.month, future.day);
    await c().create(
      type: EntryType.event,
      title: 'Late',
      start: DateTime(day.year, day.month, day.day, 15),
      end: DateTime(day.year, day.month, day.day, 16),
      alertStyle: AlertStyle.none,
      alertLead: AlertLead.atTime,
    );
    await c().create(
      type: EntryType.event,
      title: 'Early',
      start: DateTime(day.year, day.month, day.day, 9),
      end: DateTime(day.year, day.month, day.day, 10),
      alertStyle: AlertStyle.none,
      alertLead: AlertLead.atTime,
    );
    final forDay = c().entriesForDay(day);
    expect(forDay.map((e) => e.title), ['Early', 'Late']);
    expect(c().entriesForDay(day.add(const Duration(days: 2))), isEmpty);
  });
}
