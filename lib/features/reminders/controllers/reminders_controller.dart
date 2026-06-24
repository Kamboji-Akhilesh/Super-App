import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/reminder_store.dart';
import '../models/reminder.dart';
import '../models/reminder_event.dart';
import '../providers.dart';
import '../services/notification_service.dart';

/// Owns the list of reminders and drives the scheduling state machine:
/// schedule → (call) → awaiting-confirmation → (confirm) → done, with
/// reschedule/cancel transitions available throughout.
class RemindersController extends Notifier<List<Reminder>> {
  late final ReminderStore _store = ref.read(reminderStoreProvider);
  late final NotificationService _notifications =
      ref.read(notificationServiceProvider);

  @override
  List<Reminder> build() => _store.getAll();

  Reminder? byId(int id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> _persist() => _store.saveAll(state);

  void _replace(Reminder updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
  }

  /// Steps 1–3: store a reminder and schedule its first "call".
  Future<Reminder> add({
    required String task,
    required DateTime at,
    required int confirmationMinutes,
  }) async {
    final reminder = Reminder(
      id: _store.nextId(),
      task: task,
      scheduledAt: at,
      confirmationMinutes: confirmationMinutes,
      status: ReminderStatus.scheduled,
      createdAt: DateTime.now(),
    ).logged(ReminderEventType.created);
    state = [...state, reminder];
    await _persist();
    await _notifications.scheduleCall(
      id: reminder.id,
      when: at,
      title: 'Reminder',
      body: task,
      payload: 'reminder:${reminder.id}',
    );
    return reminder;
  }

  /// Edits an existing reminder's fields and re-arms its scheduled call.
  Future<void> edit({
    required int id,
    required String task,
    required DateTime at,
    required int confirmationMinutes,
  }) async {
    final existing = byId(id);
    if (existing == null) return;
    await _notifications.cancel(id);
    _replace(existing
        .copyWith(
          task: task,
          scheduledAt: at,
          confirmationMinutes: confirmationMinutes,
          status: ReminderStatus.scheduled,
        )
        .logged(ReminderEventType.edited));
    await _persist();
    await _notifications.scheduleCall(
      id: id,
      when: at,
      title: 'Reminder',
      body: task,
      payload: 'reminder:$id',
    );
  }

  /// Step 4: postpone/reschedule to a new time.
  Future<void> reschedule(int id, DateTime newAt) async {
    final r = byId(id);
    if (r == null) return;
    await _notifications.cancel(id);
    _replace(r
        .copyWith(scheduledAt: newAt, status: ReminderStatus.scheduled)
        .logged(ReminderEventType.rescheduled,
            detail: DateFormat('d MMM, h:mm a').format(newAt)));
    await _persist();
    await _notifications.scheduleCall(
      id: id,
      when: newAt,
      title: 'Reminder',
      body: r.task,
      payload: 'reminder:$id',
    );
  }

  /// Step 5: user said "okay I'll do it" → schedule the first confirmation
  /// call after the (configurable) interval.
  Future<void> startConfirmation(int id) async {
    final r = byId(id);
    if (r == null) return;
    await _scheduleConfirmation(
      r.copyWith(confirmationCount: 1).logged(ReminderEventType.willDo),
    );
  }

  /// Step 6 ("not yet"): ask again after another interval, until the retry cap
  /// is reached — then stop so it doesn't ring forever.
  Future<void> snoozeConfirmation(int id) async {
    final r = byId(id);
    if (r == null) return;
    final max = ref.read(reminderSettingsProvider).maxConfirmations;
    final next = r.confirmationCount + 1;
    if (next > max) {
      await _notifications.cancel(id);
      _replace(r.logged(ReminderEventType.gaveUp,
          detail: 'Stopped after $max check-ins'));
      await _persist();
      return;
    }
    await _scheduleConfirmation(
      r.copyWith(confirmationCount: next).logged(ReminderEventType.snoozed),
    );
  }

  Future<void> _scheduleConfirmation(Reminder reminder) async {
    final at =
        DateTime.now().add(Duration(minutes: reminder.confirmationMinutes));
    await _notifications.cancel(reminder.id);
    _replace(reminder.copyWith(status: ReminderStatus.awaitingConfirmation));
    await _persist();
    await _notifications.scheduleCall(
      id: reminder.id,
      when: at,
      title: 'Did you do it?',
      body: reminder.task,
      payload: 'reminder:${reminder.id}',
    );
  }

  /// Step 6 ("yes"): mark complete and stop calling.
  Future<void> markDone(int id) async {
    final r = byId(id);
    if (r == null) return;
    await _notifications.cancel(id);
    _replace(r.copyWith(status: ReminderStatus.done).logged(ReminderEventType.done));
    await _persist();
  }

  /// Step 8: cancel (keeps the row, stops all calls).
  Future<void> cancel(int id) async {
    final r = byId(id);
    if (r == null) return;
    await _notifications.cancel(id);
    _replace(r
        .copyWith(status: ReminderStatus.cancelled)
        .logged(ReminderEventType.cancelled));
    await _persist();
  }

  /// Step 8: delete entirely.
  Future<void> delete(int id) async {
    await _notifications.cancel(id);
    state = state.where((r) => r.id != id).toList();
    await _persist();
  }
}
