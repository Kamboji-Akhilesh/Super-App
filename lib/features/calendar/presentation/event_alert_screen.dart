import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/l10n/reminder_strings.dart';
import '../../reminders/models/voice_language.dart';
import '../../reminders/providers.dart';
import '../models/calendar_entry.dart';
import '../providers.dart';

/// Call-style alert for a calendar entry: rings until accepted (task hidden),
/// then speaks the title and offers dismiss / snooze / (mark done for tasks).
/// Reuses the reminder voice + ringtone settings.
class EventAlertScreen extends ConsumerStatefulWidget {
  const EventAlertScreen({super.key, required this.entryId});

  static const String route = '/calendar-alert';

  final int entryId;

  @override
  ConsumerState<EventAlertScreen> createState() => _EventAlertScreenState();
}

class _EventAlertScreenState extends ConsumerState<EventAlertScreen> {
  static const Duration _ringTimeout = Duration(seconds: 45);
  bool _accepted = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRinging());
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  CalendarEntry? get _entry =>
      ref.read(calendarControllerProvider.notifier).byId(widget.entryId);
  String get _langCode => ref.read(reminderSettingsProvider).languageCode;
  ReminderStrings get _s => ReminderStrings.of(_langCode);

  Future<void> _startRinging() async {
    if (_entry == null) return;
    if (ref.read(reminderSettingsProvider).ringtoneEnabled) {
      await ref.read(ringtoneServiceProvider).start();
    }
    _timeout = Timer(_ringTimeout, () {
      if (mounted && !_accepted) _snooze();
    });
  }

  Future<void> _stopRinging() async {
    _timeout?.cancel();
    await ref.read(ringtoneServiceProvider).stop();
  }

  Future<void> _accept() async {
    await _stopRinging();
    if (!mounted) return;
    setState(() => _accepted = true);
    final entry = _entry;
    if (entry != null && ref.read(reminderSettingsProvider).voiceEnabled) {
      await ref.read(ttsServiceProvider).speak(
            '${_s.incomingTitle}: ${entry.title}',
            locale: VoiceLanguage.byCode(_langCode).ttsLocale,
          );
    }
  }

  Future<void> _snooze() async {
    await _stopRinging();
    await ref.read(calendarControllerProvider.notifier).snoozeAlert(widget.entryId);
    await _close();
  }

  Future<void> _markDone() async {
    await _stopRinging();
    final entry = _entry;
    if (entry != null && entry.isTask && !entry.done) {
      await ref.read(calendarControllerProvider.notifier).toggleDone(entry.id);
    }
    await _close();
  }

  Future<void> _close() async {
    await _stopRinging();
    await ref.read(ttsServiceProvider).stop();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(calendarControllerProvider);
    final entry = _entry;
    final scheme = Theme.of(context).colorScheme;

    if (entry == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(onPressed: _close, child: const Text('Close')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 56,
                backgroundColor: scheme.primary,
                child: Icon(entry.isTask ? Icons.check_circle_outline : Icons.event,
                    size: 56, color: scheme.onPrimary),
              ),
              const SizedBox(height: 24),
              Text(_s.incomingTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              // Privacy: title hidden until accepted.
              Text(
                _accepted ? entry.title : _s.incomingSubtitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (!_accepted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Round(
                        icon: Icons.snooze,
                        color: Colors.orange,
                        label: _s.postpone,
                        onTap: _snooze),
                    _Round(
                        icon: Icons.call,
                        color: Colors.green,
                        label: _s.accept,
                        onTap: _accept),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Round(
                        icon: Icons.snooze,
                        color: Colors.orange,
                        label: _s.postpone,
                        onTap: _snooze),
                    if (entry.isTask)
                      _Round(
                          icon: Icons.check,
                          color: Colors.green,
                          label: _s.yesDone,
                          onTap: _markDone),
                    _Round(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: _s.decline,
                        onTap: _close),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
