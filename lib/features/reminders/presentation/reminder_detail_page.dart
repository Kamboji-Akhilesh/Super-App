import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../models/reminder_event.dart';
import '../providers.dart';
import 'call_screen.dart';
import 'reminder_edit_page.dart';

/// Shows a single reminder's details and full activity timeline, with actions.
class ReminderDetailPage extends ConsumerWidget {
  const ReminderDetailPage({super.key, required this.reminderId});

  static const String route = '/reminder-detail';

  final int reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild as the reminder changes; find it in the current list.
    final reminders = ref.watch(remindersControllerProvider);
    final controller = ref.read(remindersControllerProvider.notifier);
    final reminder = reminders.where((r) => r.id == reminderId).firstOrNull;

    if (reminder == null) {
      return const Scaffold(body: Center(child: Text('Reminder not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              ReminderEditPage.route,
              arguments: reminder.id,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(reminder.task,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.event,
            label: 'Scheduled',
            value: DateFormat('EEE, d MMM yyyy · h:mm a')
                .format(reminder.scheduledAt),
          ),
          _InfoRow(
            icon: Icons.flag,
            label: 'Status',
            value: _statusLabel(reminder.status),
          ),
          _InfoRow(
            icon: Icons.repeat,
            label: 'Confirm interval',
            value: reminder.confirmationMinutes == 60
                ? '1 hour'
                : '${reminder.confirmationMinutes} minutes',
          ),
          if (reminder.confirmationCount > 0)
            _InfoRow(
              icon: Icons.tag,
              label: 'Check-ins so far',
              value: '${reminder.confirmationCount}',
            ),
          const SizedBox(height: 16),
          if (reminder.isActive)
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    CallScreen.route,
                    arguments: reminder.id,
                  ),
                  icon: const Icon(Icons.phone_in_talk),
                  label: const Text('Preview call'),
                ),
                OutlinedButton.icon(
                  onPressed: () => controller.markDone(reminder.id),
                  icon: const Icon(Icons.check),
                  label: const Text('Mark done'),
                ),
                OutlinedButton.icon(
                  onPressed: () => controller.cancel(reminder.id),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          const Divider(height: 32),
          Text('Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final event in reminder.history.reversed) _EventTile(event),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile(this.event);

  final ReminderEvent event;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _describe(event);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label),
      trailing: Text(
        DateFormat('d MMM, h:mm a').format(event.at),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  (IconData, String) _describe(ReminderEvent e) => switch (e.type) {
        ReminderEventType.created => (Icons.add_task, 'Created'),
        ReminderEventType.edited => (Icons.edit, 'Edited'),
        ReminderEventType.rescheduled => (
            Icons.update,
            'Rescheduled${e.detail != null ? ' to ${e.detail}' : ''}'
          ),
        ReminderEventType.willDo => (Icons.play_arrow, "Said: I'll do it"),
        ReminderEventType.snoozed => (Icons.snooze, 'Asked again'),
        ReminderEventType.done => (Icons.check_circle, 'Marked done'),
        ReminderEventType.cancelled => (Icons.cancel, 'Cancelled'),
        ReminderEventType.gaveUp => (
            Icons.notifications_off,
            e.detail ?? 'Stopped reminding'
          ),
      };
}

String _statusLabel(ReminderStatus status) => switch (status) {
      ReminderStatus.scheduled => 'Scheduled',
      ReminderStatus.awaitingConfirmation => 'Awaiting confirmation',
      ReminderStatus.done => 'Done',
      ReminderStatus.cancelled => 'Cancelled',
    };
