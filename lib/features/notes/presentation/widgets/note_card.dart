import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../../note_palette.dart';

/// A single note tile in the masonry grid. Height is intrinsic to its content,
/// giving the wall its staggered, sticky-note feel.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = NotePalette.of(note.colorId);
    final bg = color.background(brightness);
    final fg = color.onBackground(brightness);
    final hasTitle = note.title.trim().isNotEmpty;
    final hasBody = note.body.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: fg.withValues(alpha: 0.06),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.pinned)
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      Icons.push_pin,
                      size: 16,
                      color: color.accent,
                    ),
                  ),
                if (hasTitle) ...[
                  Text(
                    note.title.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (hasBody) const SizedBox(height: 6),
                ],
                if (hasBody)
                  Text(
                    note.body.trim(),
                    maxLines: hasTitle ? 8 : 12,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.78),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
