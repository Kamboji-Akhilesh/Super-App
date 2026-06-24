import '../models/reply_intent.dart';
import 'intent_parser.dart';

/// Keyword/regex parser. Always available, fully offline, and used as the
/// fallback when no on-device model is installed.
class RuleBasedIntentParser implements IntentParser {
  const RuleBasedIntentParser();

  @override
  Future<ReplyIntent> parse(String text, {required bool confirmPhase}) async {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return ReplyIntent.unknown;

    final when = extractTime(t);

    // Explicit postpone / snooze, or any reply that named a future time.
    if (_matchesAny(t, _postponeWords) || when != null) {
      return ReplyIntent(ReplyAction.postpone, postponeTo: when);
    }

    if (confirmPhase) {
      if (_matchesAny(t, _doneWords)) return const ReplyIntent(ReplyAction.done);
      if (_matchesAny(t, _negativeWords)) {
        return const ReplyIntent(ReplyAction.notYet);
      }
      return ReplyIntent.unknown;
    }

    // First "call" phase.
    if (_matchesAny(t, _doneWords)) return const ReplyIntent(ReplyAction.done);
    if (_matchesAny(t, _doNowWords)) {
      return const ReplyIntent(ReplyAction.doItNow);
    }
    return ReplyIntent.unknown;
  }

  /// Best-effort extraction of an absolute time from natural phrasing such as
  /// "in 20 minutes", "in an hour", "tomorrow", "at 7 pm", "at 8:30".
  DateTime? extractTime(String text) {
    final now = DateTime.now();
    final t = text.toLowerCase();

    // "in/for/after N minutes/hours" (the leading word is optional).
    final relative =
        RegExp(r'(\d+)\s*(min|minute|minutes|hour|hours|hr|hrs)\b')
            .firstMatch(t);
    if (relative != null) {
      final n = int.parse(relative.group(1)!);
      final unit = relative.group(2)!;
      return unit.startsWith('h')
          ? now.add(Duration(hours: n))
          : now.add(Duration(minutes: n));
    }

    if (RegExp(r'half\s+an?\s+hour').hasMatch(t)) {
      return now.add(const Duration(minutes: 30));
    }
    if (RegExp(r'\b(in\s+)?an?\s+hour\b').hasMatch(t)) {
      return now.add(const Duration(hours: 1));
    }

    final tomorrow = t.contains('tomorrow');

    // "at 7", "at 7 pm", "at 8:30am", "7pm"
    final clock =
        RegExp(r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(t);
    if (clock != null && (tomorrow || t.contains('at') || clock.group(3) != null)) {
      var hour = int.parse(clock.group(1)!);
      final minute = int.tryParse(clock.group(2) ?? '') ?? 0;
      final meridiem = clock.group(3);
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      if (hour < 0 || hour > 23 || minute > 59) return null;

      var target =
          DateTime(now.year, now.month, now.day, hour, minute);
      if (tomorrow) target = target.add(const Duration(days: 1));
      // If the chosen time already passed today, roll to tomorrow.
      if (!tomorrow && !target.isAfter(now)) {
        target = target.add(const Duration(days: 1));
      }
      return target;
    }

    if (tomorrow) {
      // No specific time: same time tomorrow.
      return now.add(const Duration(days: 1));
    }
    return null;
  }

  bool _matchesAny(String text, List<String> needles) =>
      needles.any(text.contains);

  static const _postponeWords = [
    'postpone', 'snooze', 'later', 'remind', 'reschedule', 'not now',
    'after', 'in a bit', 'a while',
  ];
  static const _doNowWords = [
    'okay', 'ok', "i'll do it", 'will do', 'doing it', 'on it', 'sure',
    'right now', 'now', 'yes i will', 'fine',
  ];
  static const _doneWords = [
    'done', 'finished', 'completed', 'did it', 'already', 'complete', 'yep',
    'yes', 'yeah', 'yup',
  ];
  static const _negativeWords = [
    'not yet', 'no', "haven't", 'havent', "didn't", 'didnt', 'still',
    'nope', 'not done',
  ];
}
