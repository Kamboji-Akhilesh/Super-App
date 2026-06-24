import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../providers.dart';
import 'reminder_detail_page.dart';
import 'reminder_edit_page.dart';
import 'reminder_settings_page.dart';

class RemindersHomePage extends ConsumerWidget {
  const RemindersHomePage({super.key});

  static const String route = '/reminders';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = [...ref.watch(remindersControllerProvider)]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, ReminderSettingsPage.route),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, ReminderEditPage.route),
        icon: const Icon(Icons.add_alarm),
        label: const Text('New'),
      ),
      body: reminders.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: reminders.length,
              itemBuilder: (context, i) => _ReminderTile(reminders[i]),
            ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile(this.reminder);

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(remindersControllerProvider.notifier);
    final when = DateFormat('EEE, d MMM · h:mm a').format(reminder.scheduledAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _StatusIcon(reminder.status),
        title: Text(
          reminder.task,
          style: TextStyle(
            decoration: reminder.status == ReminderStatus.done
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text('$when  ·  ${_statusLabel(reminder.status)}'),
        onTap: () => Navigator.pushNamed(
          context,
          ReminderDetailPage.route,
          arguments: reminder.id,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'done':
                controller.markDone(reminder.id);
              case 'cancel':
                controller.cancel(reminder.id);
              case 'delete':
                controller.delete(reminder.id);
            }
          },
          itemBuilder: (context) => [
            if (reminder.isActive)
              const PopupMenuItem(value: 'done', child: Text('Mark done')),
            if (reminder.isActive)
              const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon(this.status);
  final ReminderStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      ReminderStatus.scheduled => (Icons.schedule, Colors.blue),
      ReminderStatus.awaitingConfirmation => (Icons.help_outline, Colors.orange),
      ReminderStatus.done => (Icons.check_circle, Colors.green),
      ReminderStatus.cancelled => (Icons.cancel, Colors.grey),
    };
    return Icon(icon, color: color);
  }
}

String _statusLabel(ReminderStatus status) => switch (status) {
      ReminderStatus.scheduled => 'Scheduled',
      ReminderStatus.awaitingConfirmation => 'Awaiting confirmation',
      ReminderStatus.done => 'Done',
      ReminderStatus.cancelled => 'Cancelled',
    };

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          const Text('No reminders yet'),
          const SizedBox(height: 4),
          const Text("Tap 'New' to add one — it'll call you when it's time."),
        ],
      ),
    );
  }
}
