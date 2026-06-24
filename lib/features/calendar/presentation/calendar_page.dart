import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../reminders/presentation/reminder_settings_page.dart';
import '../models/calendar_entry.dart';
import '../providers.dart';
import 'entry_edit_page.dart';

enum _CalView { month, week, day }

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  static const String route = '/calendar';

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  _CalView _view = _CalView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    // Watch so markers/agenda refresh when entries change.
    ref.watch(calendarControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(_focusedDay)),
        actions: [
          PopupMenuButton<_CalView>(
            icon: const Icon(Icons.calendar_view_month),
            onSelected: (v) => setState(() => _view = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _CalView.month, child: Text('Month')),
              PopupMenuItem(value: _CalView.week, child: Text('Week')),
              PopupMenuItem(value: _CalView.day, child: Text('Day')),
            ],
          ),
          IconButton(
            tooltip: 'Alert & voice settings',
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, ReminderSettingsPage.route),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          EntryEditPage.route,
          arguments: EntryEditArgs(initialDay: _selectedDay),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_view == _CalView.day)
            _DayHeader(
              day: _selectedDay,
              onPrev: () => setState(() => _selectedDay =
                  _selectedDay.subtract(const Duration(days: 1))),
              onNext: () => setState(() =>
                  _selectedDay = _selectedDay.add(const Duration(days: 1))),
            )
          else
            _buildCalendar(),
          const Divider(height: 1),
          Expanded(child: _AgendaList(day: _selectedDay)),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final controller = ref.read(calendarControllerProvider.notifier);
    return TableCalendar<CalendarEntry>(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: _focusedDay,
      headerVisible: false,
      calendarFormat:
          _view == _CalView.week ? CalendarFormat.week : CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
      eventLoader: (day) => controller.entriesForDay(day),
      onDaySelected: (selected, focused) => setState(() {
        _selectedDay = selected;
        _focusedDay = focused;
      }),
      onPageChanged: (focused) => setState(() => _focusedDay = focused),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              DateFormat('EEEE, d MMMM').format(day),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _AgendaList extends ConsumerWidget {
  const _AgendaList({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(calendarControllerProvider);
    final controller = ref.read(calendarControllerProvider.notifier);
    final entries = controller.entriesForDay(day);

    if (entries.isEmpty) {
      return const Center(child: Text('Nothing scheduled. Tap + to add.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: entries.length,
      itemBuilder: (context, i) => _EntryTile(entries[i]),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile(this.entry);

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(calendarControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final time = entry.allDay
        ? 'All day'
        : entry.isEvent && entry.end != null
            ? '${DateFormat('h:mm a').format(entry.start)} – ${DateFormat('h:mm a').format(entry.end!)}'
            : DateFormat('h:mm a').format(entry.start);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: entry.isTask
            ? Checkbox(
                value: entry.done,
                onChanged: (_) => controller.toggleDone(entry.id),
              )
            : Icon(Icons.event, color: scheme.primary),
        title: Text(
          entry.title,
          style: TextStyle(
            decoration: entry.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('$time  ·  ${_alertLabel(entry)}'),
        onTap: () => Navigator.pushNamed(
          context,
          EntryEditPage.route,
          arguments: EntryEditArgs(entryId: entry.id),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => controller.delete(entry.id),
        ),
      ),
    );
  }

  String _alertLabel(CalendarEntry e) => switch (e.alertStyle) {
        AlertStyle.none => 'No alert',
        AlertStyle.notification => 'Notify ${e.alertLead.label.toLowerCase()}',
        AlertStyle.call => 'Call ${e.alertLead.label.toLowerCase()}',
      };
}
