import 'package:flutter/foundation.dart';

@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.colorId = 0,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String body;

  /// Index into the note colour palette (see `note_palette.dart`).
  final int colorId;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether the note carries no user content (used to discard blank edits).
  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  /// First non-empty line, used as a heading fallback when [title] is blank.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = body.trim().split('\n').first.trim();
    return firstLine;
  }

  Note copyWith({
    String? title,
    String? body,
    int? colorId,
    bool? pinned,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        colorId: colorId ?? this.colorId,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'colorId': colorId,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        colorId: json['colorId'] as int? ?? 0,
        pinned: json['pinned'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
