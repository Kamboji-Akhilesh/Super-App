import 'package:flutter/foundation.dart';

/// A single entry in a reminder's activity history.
enum ReminderEventType {
  created,
  edited,
  rescheduled,
  willDo, // user said "I'll do it now"
  snoozed, // confirmation "not yet" → asked again
  done,
  cancelled,
  gaveUp, // hit the confirmation retry cap
}

@immutable
class ReminderEvent {
  const ReminderEvent({required this.type, required this.at, this.detail});

  final ReminderEventType type;
  final DateTime at;

  /// Optional extra context, e.g. the new time for a reschedule.
  final String? detail;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'at': at.toIso8601String(),
        if (detail != null) 'detail': detail,
      };

  factory ReminderEvent.fromJson(Map<String, dynamic> json) => ReminderEvent(
        type: ReminderEventType.values.byName(json['type'] as String),
        at: DateTime.parse(json['at'] as String),
        detail: json['detail'] as String?,
      );
}
