import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../note_palette.dart';
import '../providers.dart';

/// Route argument for [NoteEditPage]. A null [noteId] opens a fresh note.
class NoteEditArgs {
  const NoteEditArgs({this.noteId});
  final int? noteId;
}

/// Immersive single-note editor. The whole screen adopts the note's colour and
/// changes save automatically when the user navigates back.
class NoteEditPage extends ConsumerStatefulWidget {
  const NoteEditPage({super.key, this.noteId});

  static const String route = '/notes/edit';

  final int? noteId;

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  final _bodyFocus = FocusNode();

  int? _id; // null until first save (for new notes)
  int _colorId = 0;
  bool _pinned = false;
  DateTime? _updatedAt;
  bool _discarded = false;

  @override
  void initState() {
    super.initState();
    final existing =
        widget.noteId == null ? null : ref.read(notesControllerProvider.notifier).byId(widget.noteId!);
    _id = existing?.id;
    _colorId = existing?.colorId ?? 0;
    _pinned = existing?.pinned ?? false;
    _updatedAt = existing?.updatedAt;
    _title = TextEditingController(text: existing?.title ?? '');
    _body = TextEditingController(text: existing?.body ?? '');

    if (existing == null) {
      // New note: drop the cursor straight into the body for fast capture.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _bodyFocus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_discarded) return;
    final controller = ref.read(notesControllerProvider.notifier);
    final title = _title.text;
    final body = _body.text;

    if (_id == null) {
      if (title.trim().isEmpty && body.trim().isEmpty) return;
      final created = await controller.create(
        title: title,
        body: body,
        colorId: _colorId,
      );
      _id = created?.id;
      if (_pinned && _id != null) await controller.togglePin(_id!);
    } else {
      await controller.update(_id!, title: title, body: body, colorId: _colorId);
    }
  }

  Future<void> _togglePin() async {
    setState(() => _pinned = !_pinned);
    if (_id != null) {
      await ref.read(notesControllerProvider.notifier).togglePin(_id!);
    }
  }

  void _setColor(int colorId) {
    setState(() => _colorId = colorId);
    if (_id != null) {
      ref.read(notesControllerProvider.notifier).setColor(_id!, colorId);
    }
  }

  Future<void> _delete() async {
    _discarded = true;
    if (_id != null) {
      await ref.read(notesControllerProvider.notifier).delete(_id!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = NotePalette.of(_colorId);
    final bg = color.background(brightness);
    final fg = color.onBackground(brightness);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) => _save(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: fg,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: _pinned ? 'Unpin' : 'Pin',
              icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: _togglePin,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  TextField(
                    controller: _title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        color: fg.withValues(alpha: 0.4),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    focusNode: _bodyFocus,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.45,
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Start writing…',
                      hintStyle: TextStyle(
                        color: fg.withValues(alpha: 0.4),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _ColorStrip(
              selected: _colorId,
              fg: fg,
              updatedAt: _updatedAt,
              onSelected: _setColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar: an edited-time label plus the row of selectable colour swatches.
class _ColorStrip extends StatelessWidget {
  const _ColorStrip({
    required this.selected,
    required this.fg,
    required this.updatedAt,
    required this.onSelected,
  });

  final int selected;
  final Color fg;
  final DateTime? updatedAt;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Edited ${_relative(updatedAt!)}',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: NotePalette.colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final c = NotePalette.colors[i];
                  final isSelected = i == selected;
                  return GestureDetector(
                    onTap: () => onSelected(i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? fg : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && now.day == t.day) {
      return DateFormat.jm().format(t);
    }
    if (diff.inDays < 7) return DateFormat('EEE, h:mm a').format(t);
    return DateFormat('MMM d, yyyy').format(t);
  }
}
