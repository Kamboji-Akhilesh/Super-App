import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/reminders_controller.dart';
import '../l10n/reminder_strings.dart';
import '../models/reminder.dart';
import '../models/reply_intent.dart';
import '../models/voice_language.dart';
import '../providers.dart';

/// Full-screen, incoming-call-style screen shown when a reminder fires.
///
/// Privacy-first: it rings (looping tone) showing only a neutral "Reminder
/// calling…" — the task and the spoken prompt stay hidden until the user
/// **accepts**. After accepting, it speaks the task (in the chosen language),
/// listens for a spoken reply, and branches. Buttons remain a fallback.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.reminderId});

  static const String route = '/reminder-call';

  final int reminderId;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

enum _Phase { ringing, active }

enum _Stage { idle, listening, thinking, askingWhen }

class _CallScreenState extends ConsumerState<CallScreen> {
  static const Duration _ringTimeout = Duration(seconds: 45);

  _Phase _phase = _Phase.ringing;
  _Stage _stage = _Stage.idle;
  String _transcript = '';
  bool _sttAvailable = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRinging());
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  // --- context helpers ------------------------------------------------------

  Reminder? get _current =>
      ref.read(remindersControllerProvider.notifier).byId(widget.reminderId);
  RemindersController get _controller =>
      ref.read(remindersControllerProvider.notifier);
  bool get _isConfirm =>
      _current?.status == ReminderStatus.awaitingConfirmation;
  bool get _voiceOn => ref.read(reminderSettingsProvider).voiceEnabled;
  String get _langCode => ref.read(reminderSettingsProvider).languageCode;
  ReminderStrings get _s => ReminderStrings.of(_langCode);
  String get _ttsLocale => VoiceLanguage.byCode(_langCode).ttsLocale;

  // --- ringing phase --------------------------------------------------------

  Future<void> _startRinging() async {
    final reminder = _current;
    if (reminder == null || !reminder.isActive) return;
    if (ref.read(reminderSettingsProvider).ringtoneEnabled) {
      await ref.read(ringtoneServiceProvider).start();
    }
    // Nobody answered → stop ringing and try again later.
    _timeoutTimer = Timer(_ringTimeout, () {
      if (mounted && _phase == _Phase.ringing) _decline();
    });
  }

  Future<void> _stopRinging() async {
    _timeoutTimer?.cancel();
    await ref.read(ringtoneServiceProvider).stop();
  }

  Future<void> _accept() async {
    await _stopRinging();
    if (!mounted) return;
    setState(() => _phase = _Phase.active);
    _beginActive();
  }

  Future<void> _decline() async {
    await _stopRinging();
    // First call → ring again after the interval; confirmation call → snooze.
    if (_isConfirm) {
      await _controller.snoozeConfirmation(widget.reminderId);
    } else {
      final r = _current;
      if (r != null) {
        await _controller.reschedule(
          widget.reminderId,
          DateTime.now().add(Duration(minutes: r.confirmationMinutes)),
        );
      }
    }
    await _close();
  }

  // --- active phase ---------------------------------------------------------

  Future<void> _beginActive() async {
    final reminder = _current;
    if (reminder == null || !reminder.isActive) return;
    if (_voiceOn) {
      await ref.read(ttsServiceProvider).speak(
            _isConfirm ? _s.confirmPrompt : _s.timePrompt(reminder.task),
            locale: _ttsLocale,
          );
    }
    _sttAvailable = await ref.read(speechServiceProvider).ensureInitialised();
    if (mounted && _voiceOn && _sttAvailable) _listen(forWhen: false);
  }

  Future<void> _listen({required bool forWhen}) async {
    setState(() {
      _stage = forWhen ? _Stage.askingWhen : _Stage.listening;
      _transcript = '';
    });
    await ref.read(speechServiceProvider).listen(
      localeTag: _ttsLocale,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _transcript = text);
        if (isFinal && text.trim().isNotEmpty) {
          forWhen ? _handleWhen(text) : _handleReply(text);
        }
      },
    );
  }

  Future<void> _handleReply(String text) async {
    setState(() => _stage = _Stage.thinking);
    final intent = await ref
        .read(nluServiceProvider)
        .interpret(text, confirmPhase: _isConfirm);
    if (!mounted) return;
    switch (intent.action) {
      case ReplyAction.done:
        await _act(() => _controller.markDone(widget.reminderId));
      case ReplyAction.doItNow:
        await _act(() => _controller.startConfirmation(widget.reminderId));
      case ReplyAction.notYet:
        await _act(() => _controller.snoozeConfirmation(widget.reminderId));
      case ReplyAction.postpone:
        if (intent.postponeTo != null) {
          await _act(() =>
              _controller.reschedule(widget.reminderId, intent.postponeTo!));
        } else {
          await _askWhen();
        }
      case ReplyAction.unknown:
        await _sayAndIdle(_s.didntCatch);
    }
  }

  Future<void> _askWhen() async {
    if (_voiceOn) {
      await ref.read(ttsServiceProvider).speak(_s.askWhen, locale: _ttsLocale);
    }
    if (mounted && _sttAvailable) {
      _listen(forWhen: true);
    } else {
      _postpone();
    }
  }

  Future<void> _handleWhen(String text) async {
    setState(() => _stage = _Stage.thinking);
    final when = ref.read(nluServiceProvider).parseWhen(text);
    if (!mounted) return;
    if (when != null) {
      await _act(() => _controller.reschedule(widget.reminderId, when));
    } else {
      await _sayAndIdle(_s.noTimeHeard);
    }
  }

  Future<void> _sayAndIdle(String message) async {
    setState(() => _stage = _Stage.idle);
    if (_voiceOn) {
      await ref.read(ttsServiceProvider).speak(message, locale: _ttsLocale);
    }
  }

  // --- shared actions -------------------------------------------------------

  Future<void> _stopVoice() async {
    await ref.read(ttsServiceProvider).stop();
    await ref.read(speechServiceProvider).cancel();
  }

  Future<void> _close() async {
    await _stopRinging();
    await _stopVoice();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _act(Future<void> Function() action) async {
    await _stopVoice();
    await action();
    await _close();
  }

  Future<void> _postpone() async {
    final id = widget.reminderId;
    final choice = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.snooze),
              title: const Text('In 15 minutes'),
              onTap: () => Navigator.pop(
                  sheetContext, DateTime.now().add(const Duration(minutes: 15))),
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('In 1 hour'),
              onTap: () => Navigator.pop(
                  sheetContext, DateTime.now().add(const Duration(hours: 1))),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Pick a time…'),
              onTap: () async {
                final picked = await _pickDateTime();
                if (sheetContext.mounted) Navigator.pop(sheetContext, picked);
              },
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await _act(() => _controller.reschedule(id, choice));
    }
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30))),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(remindersControllerProvider); // rebuild on changes
    final reminder = _current;
    final scheme = Theme.of(context).colorScheme;

    if (reminder == null || !reminder.isActive) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This reminder is no longer active.'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _close, child: const Text('Close')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _phase == _Phase.ringing
              ? _buildRinging(scheme)
              : _buildActive(reminder, scheme),
        ),
      ),
    );
  }

  Widget _buildRinging(ColorScheme scheme) {
    return Column(
      children: [
        const Spacer(),
        CircleAvatar(
          radius: 56,
          backgroundColor: scheme.primary,
          child: Icon(Icons.notifications_active,
              size: 56, color: scheme.onPrimary),
        ),
        const SizedBox(height: 24),
        Text(_s.incomingTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(_s.incomingSubtitle,
            style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoundAction(
              icon: Icons.call_end,
              color: Colors.red,
              label: _s.decline,
              onTap: _decline,
            ),
            _RoundAction(
              icon: Icons.call,
              color: Colors.green,
              label: _s.accept,
              onTap: _accept,
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActive(Reminder reminder, ColorScheme scheme) {
    return Column(
      children: [
        const Spacer(),
        CircleAvatar(
          radius: 56,
          backgroundColor: scheme.primary,
          child: Icon(_isConfirm ? Icons.help_outline : Icons.alarm,
              size: 56, color: scheme.onPrimary),
        ),
        const SizedBox(height: 24),
        Text(_isConfirm ? _s.checkingIn : _s.incomingTitle,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          reminder.task,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _VoiceStatus(stage: _stage, transcript: _transcript, strings: _s),
        const Spacer(),
        if (_isConfirm)
          _ConfirmActions(
            strings: _s,
            onYes: () => _act(() => _controller.markDone(reminder.id)),
            onNotYet: () =>
                _act(() => _controller.snoozeConfirmation(reminder.id)),
          )
        else
          _CallActions(
            strings: _s,
            onDoNow: () =>
                _act(() => _controller.startConfirmation(reminder.id)),
            onPostpone: _postpone,
            onDone: () => _act(() => _controller.markDone(reminder.id)),
          ),
        const SizedBox(height: 8),
        if (_sttAvailable)
          TextButton.icon(
            onPressed: _stage == _Stage.listening
                ? null
                : () => _listen(forWhen: _stage == _Stage.askingWhen),
            icon: const Icon(Icons.mic),
            label: Text(_stage == _Stage.listening ? _s.listening : _s.tapToSpeak),
          ),
      ],
    );
  }
}

class _VoiceStatus extends StatelessWidget {
  const _VoiceStatus({
    required this.stage,
    required this.transcript,
    required this.strings,
  });

  final _Stage stage;
  final String transcript;
  final ReminderStrings strings;

  @override
  Widget build(BuildContext context) {
    final label = switch (stage) {
      _Stage.listening => strings.listening,
      _Stage.thinking => strings.thinking,
      _Stage.askingWhen => strings.askWhen,
      _Stage.idle => '',
    };
    if (label.isEmpty && transcript.isEmpty) return const SizedBox(height: 24);
    return Column(
      children: [
        if (label.isNotEmpty)
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        if (transcript.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('“$transcript”',
                style: const TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

class _CallActions extends StatelessWidget {
  const _CallActions({
    required this.strings,
    required this.onDoNow,
    required this.onPostpone,
    required this.onDone,
  });

  final ReminderStrings strings;
  final VoidCallback onDoNow;
  final VoidCallback onPostpone;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoundAction(
              icon: Icons.snooze,
              color: Colors.orange,
              label: strings.postpone,
              onTap: onPostpone,
            ),
            _RoundAction(
              icon: Icons.play_arrow,
              color: Colors.green,
              label: strings.doNow,
              onTap: onDoNow,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onDone,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(strings.alreadyDone),
        ),
      ],
    );
  }
}

class _ConfirmActions extends StatelessWidget {
  const _ConfirmActions({
    required this.strings,
    required this.onYes,
    required this.onNotYet,
  });

  final ReminderStrings strings;
  final VoidCallback onYes;
  final VoidCallback onNotYet;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundAction(
          icon: Icons.close,
          color: Colors.red,
          label: strings.notYet,
          onTap: onNotYet,
        ),
        _RoundAction(
          icon: Icons.check,
          color: Colors.green,
          label: strings.yesDone,
          onTap: onYes,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
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
