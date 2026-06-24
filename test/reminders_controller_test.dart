import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/providers.dart';
import 'package:super_app/features/reminders/controllers/reminders_controller.dart';
import 'package:super_app/features/reminders/models/reminder.dart';
import 'package:super_app/features/reminders/models/reminder_event.dart';
import 'package:super_app/features/reminders/providers.dart';
import 'package:super_app/features/reminders/services/notification_service.dart';

/// Records scheduling calls and skips all platform work.
class _FakeNotifications extends NotificationService {
  final Set<int> scheduled = {};

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
  }) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }
}

void main() {
  late ProviderContainer container;
  late _FakeNotifications notifications;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    notifications = _FakeNotifications();
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationServiceProvider.overrideWithValue(notifications),
    ]);
  });

  tearDown(() => container.dispose());

  RemindersController controller() =>
      container.read(remindersControllerProvider.notifier);
  List<Reminder> state() => container.read(remindersControllerProvider);

  test('add schedules a reminder in scheduled state', () async {
    final r = await controller().add(
      task: 'do the laundry',
      at: DateTime.now().add(const Duration(hours: 1)),
      confirmationMinutes: 5,
    );

    expect(state(), hasLength(1));
    expect(state().single.status, ReminderStatus.scheduled);
    expect(notifications.scheduled, contains(r.id));
  });

  test('"I\'ll do it" moves to awaiting confirmation and reschedules', () async {
    final r = await controller()
        .add(task: 't', at: DateTime.now().add(const Duration(hours: 1)), confirmationMinutes: 10);

    await controller().startConfirmation(r.id);

    expect(controller().byId(r.id)!.status, ReminderStatus.awaitingConfirmation);
    expect(notifications.scheduled, contains(r.id)); // confirmation re-armed
  });

  test('markDone completes and cancels the alarm', () async {
    final r = await controller()
        .add(task: 't', at: DateTime.now().add(const Duration(hours: 1)), confirmationMinutes: 5);

    await controller().markDone(r.id);

    expect(controller().byId(r.id)!.status, ReminderStatus.done);
    expect(notifications.scheduled, isNot(contains(r.id)));
  });

  test('reschedule updates the time and keeps it scheduled', () async {
    final r = await controller()
        .add(task: 't', at: DateTime.now().add(const Duration(hours: 1)), confirmationMinutes: 5);
    final newAt = DateTime.now().add(const Duration(hours: 3));

    await controller().reschedule(r.id, newAt);

    final updated = controller().byId(r.id)!;
    expect(updated.status, ReminderStatus.scheduled);
    expect(updated.scheduledAt, newAt);
  });

  test('cancel keeps the row but stops calls; delete removes it', () async {
    final r = await controller()
        .add(task: 't', at: DateTime.now().add(const Duration(hours: 1)), confirmationMinutes: 5);

    await controller().cancel(r.id);
    expect(controller().byId(r.id)!.status, ReminderStatus.cancelled);
    expect(notifications.scheduled, isNot(contains(r.id)));

    await controller().delete(r.id);
    expect(state(), isEmpty);
  });

  test('confirmation stops after the retry cap and logs history', () async {
    final r = await controller().add(
      task: 't',
      at: DateTime.now().add(const Duration(hours: 1)),
      confirmationMinutes: 5,
    );

    await controller().startConfirmation(r.id); // count = 1
    // Default cap is 3, so two more snoozes stay scheduled, the next gives up.
    await controller().snoozeConfirmation(r.id); // 2
    await controller().snoozeConfirmation(r.id); // 3
    expect(controller().byId(r.id)!.confirmationCount, 3);
    expect(notifications.scheduled, contains(r.id));

    await controller().snoozeConfirmation(r.id); // 4 > cap → give up
    expect(notifications.scheduled, isNot(contains(r.id)));
    expect(
      controller().byId(r.id)!.history.last.type,
      ReminderEventType.gaveUp,
    );
  });

  test('history records the lifecycle', () async {
    final r = await controller().add(
      task: 't',
      at: DateTime.now().add(const Duration(hours: 1)),
      confirmationMinutes: 5,
    );
    await controller().markDone(r.id);
    final types = controller().byId(r.id)!.history.map((e) => e.type).toList();
    expect(types, containsAllInOrder([
      ReminderEventType.created,
      ReminderEventType.done,
    ]));
  });

  test('reminders persist across controller rebuilds', () async {
    await controller()
        .add(task: 'persisted', at: DateTime.now().add(const Duration(hours: 1)), confirmationMinutes: 5);

    container.invalidate(remindersControllerProvider);
    expect(state().single.task, 'persisted');
  });
}
