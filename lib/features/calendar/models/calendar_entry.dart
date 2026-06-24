import 'package:flutter/foundation.dart';

/// Whether an entry is a point-in-time task (checkable) or a timed event.
enum EntryType { task, event }

/// How the alert is delivered when it fires.
enum AlertStyle {
  none('No alert'),
  notification('Notification'),
  call('Call');

  const AlertStyle(this.label);
  final String label;
}

/// How far before the start the alert fires (Google-Calendar style).
enum AlertLead {
  atTime(0, 'At time'),
  min5(5, '5 minutes before'),
  min10(10, '10 minutes before'),
  min30(30, '30 minutes before'),
  hour1(60, '1 hour before'),
  day1(1440, '1 day before');

  const AlertLead(this.minutes, this.label);
  final int minutes;
  final String label;
}

@immutable
class CalendarEntry {
  const CalendarEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.done = false,
    this.alertStyle = AlertStyle.notification,
    this.alertLead = AlertLead.atTime,
    required this.createdAt,
  });

  final int id;
  final EntryType type;
  final String title;

  /// Event start, or task due time.
  final DateTime start;

  /// Event end (events only).
  final DateTime? end;
  final bool allDay;

  /// Completion flag (tasks).
  final bool done;

  final AlertStyle alertStyle;
  final AlertLead alertLead;
  final DateTime createdAt;

  bool get isTask => type == EntryType.task;
  bool get isEvent => type == EntryType.event;

  /// When the alert should fire, or null if no alert.
  DateTime? get alertTime => alertStyle == AlertStyle.none
      ? null
      : start.subtract(Duration(minutes: alertLead.minutes));

  CalendarEntry copyWith({
    EntryType? type,
    String? title,
    DateTime? start,
    DateTime? end,
    bool? allDay,
    bool? done,
    AlertStyle? alertStyle,
    AlertLead? alertLead,
  }) =>
      CalendarEntry(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        start: start ?? this.start,
        end: end ?? this.end,
        allDay: allDay ?? this.allDay,
        done: done ?? this.done,
        alertStyle: alertStyle ?? this.alertStyle,
        alertLead: alertLead ?? this.alertLead,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'allDay': allDay,
        'done': done,
        'alertStyle': alertStyle.name,
        'alertLead': alertLead.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CalendarEntry.fromJson(Map<String, dynamic> json) => CalendarEntry(
        id: json['id'] as int,
        type: EntryType.values.byName(json['type'] as String),
        title: json['title'] as String,
        start: DateTime.parse(json['start'] as String),
        end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
        allDay: json['allDay'] as bool? ?? false,
        done: json['done'] as bool? ?? false,
        alertStyle: AlertStyle.values.byName(json['alertStyle'] as String),
        alertLead: AlertLead.values.byName(json['alertLead'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
