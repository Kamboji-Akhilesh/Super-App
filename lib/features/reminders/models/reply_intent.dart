/// What the user's spoken/typed reply on the call screen means.
enum ReplyAction {
  /// "okay, I'll do it now" → start the confirmation countdown.
  doItNow,

  /// "postpone / snooze / remind me later" → reschedule.
  postpone,

  /// "yes / done / already did it" → complete.
  done,

  /// "not yet / no" → ask again later.
  notYet,

  /// Couldn't be understood — fall back to on-screen buttons.
  unknown,
}

/// Parsed reply: an [action] plus, for a postponement, an optional target time.
class ReplyIntent {
  const ReplyIntent(this.action, {this.postponeTo});

  final ReplyAction action;

  /// Absolute time to reschedule to, when the reply contained one.
  final DateTime? postponeTo;

  static const unknown = ReplyIntent(ReplyAction.unknown);
}
