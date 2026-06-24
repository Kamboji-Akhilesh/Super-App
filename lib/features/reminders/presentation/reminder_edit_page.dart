import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/reminder_settings.dart';
import '../providers.dart';

/// Add or edit a reminder. Pass the reminder id as the route argument to edit;
/// pass nothing to create a new one.
class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({super.key, this.reminderId});

  static const String route = '/reminder-edit';

  final int? reminderId;

  @override
  ConsumerState<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends ConsumerState<ReminderEditPage> {
  final _taskController = TextEditingController();
  late DateTime _when;
  late int _confirmMinutes;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    final existing = widget.reminderId == null
        ? null
        : ref.read(remindersControllerProvider.notifier).byId(widget.reminderId!);

    if (existing != null) {
      _taskController.text = existing.task;
      _when = existing.scheduledAt;
      _confirmMinutes = existing.confirmationMinutes;
    } else {
      _when = _roundUp(DateTime.now().add(const Duration(minutes: 1)));
      _confirmMinutes =
          ref.read(reminderSettingsProvider).defaultConfirmationMinutes;
    }
  }

  static DateTime _roundUp(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute);

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.reminderId != null;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _when =
          DateTime(date.year, date.month, date.day, _when.hour, _when.minute));
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time != null) {
      setState(() => _when = DateTime(
          _when.year, _when.month, _when.day, time.hour, time.minute));
    }
  }

  Future<void> _save() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) {
      _snack('Please enter what to be reminded about.');
      return;
    }
    if (_when.isBefore(DateTime.now())) {
      _snack('Pick a time in the future.');
      return;
    }

    final controller = ref.read(remindersControllerProvider.notifier);
    if (_isEditing) {
      await controller.edit(
        id: widget.reminderId!,
        task: task,
        at: _when,
        confirmationMinutes: _confirmMinutes,
      );
    } else {
      await controller.add(
        task: task,
        at: _when,
        confirmationMinutes: _confirmMinutes,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit reminder' : 'New reminder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _taskController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Remind me to…',
              hintText: 'e.g. do the laundry',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('EEE, d MMM yyyy').format(_when)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(DateFormat('h:mm a').format(_when)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _confirmMinutes,
            decoration: const InputDecoration(
              labelText: 'Confirm again after',
              border: OutlineInputBorder(),
              helperText:
                  "When you say you'll do it, I'll call back after this to check.",
            ),
            items: [
              for (final m in ReminderSettings.intervalChoices)
                DropdownMenuItem(value: m, child: Text(_minutesLabel(m))),
            ],
            onChanged: (v) => setState(() => _confirmMinutes = v ?? _confirmMinutes),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(_isEditing ? 'Save changes' : 'Create reminder'),
          ),
        ],
      ),
    );
  }
}

String _minutesLabel(int m) => m == 60 ? '1 hour' : '$m minutes';
