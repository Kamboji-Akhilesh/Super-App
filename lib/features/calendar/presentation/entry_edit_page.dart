import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/calendar_entry.dart';
import '../providers.dart';

/// Route arguments for [EntryEditPage].
class EntryEditArgs {
  const EntryEditArgs({this.entryId, this.initialDay});
  final int? entryId;
  final DateTime? initialDay;
}

/// Shared "new / edit" sheet for both tasks and events. Pass [entryId] to edit
/// and [initialDay] to default the date when creating.
class EntryEditPage extends ConsumerStatefulWidget {
  const EntryEditPage({super.key, this.entryId, this.initialDay});

  static const String route = '/calendar-entry-edit';

  final int? entryId;
  final DateTime? initialDay;

  @override
  ConsumerState<EntryEditPage> createState() => _EntryEditPageState();
}

class _EntryEditPageState extends ConsumerState<EntryEditPage> {
  final _titleController = TextEditingController();
  EntryType _type = EntryType.event;
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _allDay = false;
  AlertStyle _alertStyle = AlertStyle.notification;
  AlertLead _alertLead = AlertLead.atTime;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    final existing = widget.entryId == null
        ? null
        : ref.read(calendarControllerProvider.notifier).byId(widget.entryId!);

    if (existing != null) {
      _type = existing.type;
      _titleController.text = existing.title;
      _date = existing.start;
      _startTime = TimeOfDay.fromDateTime(existing.start);
      _endTime = TimeOfDay.fromDateTime(
          existing.end ?? existing.start.add(const Duration(hours: 1)));
      _allDay = existing.allDay;
      _alertStyle = existing.alertStyle;
      _alertLead = existing.alertLead;
    } else {
      final base = widget.initialDay ?? DateTime.now();
      _date = DateTime(base.year, base.month, base.day);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.entryId != null;

  DateTime _combine(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (t == null) return;
    setState(() {
      if (start) {
        _startTime = t;
        // Keep end after start for events.
        if (_type == EntryType.event &&
            _combine(_endTime).isBefore(_combine(t))) {
          _endTime = TimeOfDay(hour: (t.hour + 1) % 24, minute: t.minute);
        }
      } else {
        _endTime = t;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _snack('Please enter a title.');
      return;
    }
    final start = _allDay
        ? DateTime(_date.year, _date.month, _date.day, 9)
        : _combine(_startTime);
    DateTime? end;
    if (_type == EntryType.event && !_allDay) {
      end = _combine(_endTime);
      if (!end.isAfter(start)) {
        _snack('End time must be after the start time.');
        return;
      }
    }

    final controller = ref.read(calendarControllerProvider.notifier);
    if (_isEditing) {
      final existing =
          ref.read(calendarControllerProvider.notifier).byId(widget.entryId!)!;
      await controller.update(existing.copyWith(
        type: _type,
        title: title,
        start: start,
        end: end,
        allDay: _allDay,
        alertStyle: _alertStyle,
        alertLead: _alertLead,
      ));
    } else {
      await controller.create(
        type: _type,
        title: title,
        start: start,
        end: end,
        allDay: _allDay,
        alertStyle: _alertStyle,
        alertLead: _alertLead,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final isEvent = _type == EntryType.event;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit' : 'New')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SegmentedButton<EntryType>(
              segments: const [
                ButtonSegment(
                    value: EntryType.event,
                    icon: Icon(Icons.event),
                    label: Text('Event')),
                ButtonSegment(
                    value: EntryType.task,
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Task')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: isEvent ? 'Event title' : 'Task title',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat('EEE, d MMM yyyy').format(_date)),
            onTap: _pickDate,
          ),
          if (isEvent)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day'),
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
            ),
          if (!_allDay)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                        '${isEvent ? 'Start' : 'Due'}: ${_startTime.format(context)}'),
                  ),
                ),
                if (isEvent) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.access_time_filled),
                      label: Text('End: ${_endTime.format(context)}'),
                    ),
                  ),
                ],
              ],
            ),
          const Divider(height: 32),
          DropdownButtonFormField<AlertStyle>(
            initialValue: _alertStyle,
            decoration: const InputDecoration(
              labelText: 'Alert',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in AlertStyle.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (v) => setState(() => _alertStyle = v ?? _alertStyle),
          ),
          if (_alertStyle != AlertStyle.none) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<AlertLead>(
              initialValue: _alertLead,
              decoration: const InputDecoration(
                labelText: 'When',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final l in AlertLead.values)
                  DropdownMenuItem(value: l, child: Text(l.label)),
              ],
              onChanged: (v) => setState(() => _alertLead = v ?? _alertLead),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(_isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }
}
