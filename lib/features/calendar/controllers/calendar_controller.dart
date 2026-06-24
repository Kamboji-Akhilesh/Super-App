import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/providers.dart' show notificationServiceProvider;
import '../../reminders/services/notification_service.dart';
import '../data/calendar_store.dart';
import '../models/calendar_entry.dart';
import '../providers.dart';

/// Owns calendar entries (tasks + events) and schedules their alerts
/// (notification- or call-style) through the shared [NotificationService].
class CalendarController extends Notifier<List<CalendarEntry>> {
  late final CalendarStore _store = ref.read(calendarStoreProvider);
  late final NotificationService _notifications =
      ref.read(notificationServiceProvider);

  /// Calendar notification ids are offset to avoid colliding with reminder ids
  /// (both features draw from their own 1-based sequences).
  static const int _notifBase = 1000000;
  int _notifId(int entryId) => _notifBase + entryId;

  @override
  List<CalendarEntry> build() => _store.getAll();

  CalendarEntry? byId(int id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Entries whose start falls on [day], sorted by time (all-day first).
  List<CalendarEntry> entriesForDay(DateTime day) {
    final list = state.where((e) => _sameDay(e.start, day)).toList()
      ..sort((a, b) {
        if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
        return a.start.compareTo(b.start);
      });
    return list;
  }

  Future<void> create({
    required EntryType type,
    required String title,
    required DateTime start,
    DateTime? end,
    bool allDay = false,
    required AlertStyle alertStyle,
    required AlertLead alertLead,
  }) async {
    final entry = CalendarEntry(
      id: _store.nextId(),
      type: type,
      title: title,
      start: start,
      end: end,
      allDay: allDay,
      alertStyle: alertStyle,
      alertLead: alertLead,
      createdAt: DateTime.now(),
    );
    state = [...state, entry];
    await _persist();
    await _reschedule(entry);
  }

  Future<void> update(CalendarEntry entry) async {
    _replace(entry);
    await _persist();
    await _reschedule(entry);
  }

  Future<void> delete(int id) async {
    await _notifications.cancel(_notifId(id));
    state = state.where((e) => e.id != id).toList();
    await _persist();
  }

  Future<void> toggleDone(int id) async {
    final e = byId(id);
    if (e == null) return;
    final updated = e.copyWith(done: !e.done);
    _replace(updated);
    await _persist();
    await _reschedule(updated); // a completed task cancels its alert
  }

  // --- internals ------------------------------------------------------------

  Future<void> _persist() => _store.saveAll(state);

  void _replace(CalendarEntry updated) {
    state = [
      for (final e in state)
        if (e.id == updated.id) updated else e,
    ];
  }

  /// Re-fires this entry's alert after [minutes] (used by the call screen's
  /// "snooze"), without changing the entry itself.
  Future<void> snoozeAlert(int id, {int minutes = 10}) async {
    final e = byId(id);
    if (e == null) return;
    await _scheduleAt(e, DateTime.now().add(Duration(minutes: minutes)));
  }

  Future<void> _reschedule(CalendarEntry e) async {
    await _notifications.cancel(_notifId(e.id));
    final at = e.alertTime;
    if (at == null || at.isBefore(DateTime.now())) return;
    if (e.isTask && e.done) return;
    await _scheduleAt(e, at);
  }

  Future<void> _scheduleAt(CalendarEntry e, DateTime at) async {
    final body = e.isEvent ? 'Event' : 'Task';
    if (e.alertStyle == AlertStyle.call) {
      await _notifications.scheduleCall(
        id: _notifId(e.id),
        when: at,
        title: e.title,
        body: body,
        payload: 'calendar:${e.id}:call',
      );
    } else if (e.alertStyle == AlertStyle.notification) {
      await _notifications.scheduleNotification(
        id: _notifId(e.id),
        when: at,
        title: e.title,
        body: body,
        payload: 'calendar:${e.id}:notif',
      );
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
