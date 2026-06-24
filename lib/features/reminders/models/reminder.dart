import 'package:flutter/foundation.dart';

import 'reminder_event.dart';

/// Lifecycle of a reminder.
enum ReminderStatus {
  /// Waiting for its scheduled time to fire the first "call".
  scheduled,

  /// User said they'd do it; waiting for a confirmation "call".
  awaitingConfirmation,

  /// Completed.
  done,

  /// Cancelled by the user (kept in the list, but no longer fires).
  cancelled,
}

@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.task,
    required this.scheduledAt,
    required this.confirmationMinutes,
    required this.status,
    required this.createdAt,
    this.confirmationCount = 0,
    this.history = const [],
  });

  /// Stable id; also used as the notification id.
  final int id;
  final String task;
  final DateTime scheduledAt;

  /// Minutes to wait before the follow-up "are you done?" call.
  final int confirmationMinutes;
  final ReminderStatus status;
  final DateTime createdAt;

  /// How many confirmation "calls" have been scheduled so far (for the cap).
  final int confirmationCount;

  /// Activity log, newest last.
  final List<ReminderEvent> history;

  bool get isActive =>
      status == ReminderStatus.scheduled ||
      status == ReminderStatus.awaitingConfirmation;

  Reminder copyWith({
    String? task,
    DateTime? scheduledAt,
    int? confirmationMinutes,
    ReminderStatus? status,
    int? confirmationCount,
    List<ReminderEvent>? history,
  }) =>
      Reminder(
        id: id,
        task: task ?? this.task,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        confirmationMinutes: confirmationMinutes ?? this.confirmationMinutes,
        status: status ?? this.status,
        createdAt: createdAt,
        confirmationCount: confirmationCount ?? this.confirmationCount,
        history: history ?? this.history,
      );

  /// Returns a copy with [event] appended to the history.
  Reminder logged(ReminderEventType type, {String? detail}) => copyWith(
        history: [
          ...history,
          ReminderEvent(type: type, at: DateTime.now(), detail: detail),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'scheduledAt': scheduledAt.toIso8601String(),
        'confirmationMinutes': confirmationMinutes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'confirmationCount': confirmationCount,
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as int,
        task: json['task'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        confirmationMinutes: json['confirmationMinutes'] as int? ?? 5,
        status: ReminderStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        confirmationCount: json['confirmationCount'] as int? ?? 0,
        history: (json['history'] as List<dynamic>? ?? [])
            .map((e) => ReminderEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
