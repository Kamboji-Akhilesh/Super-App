import '../models/reply_intent.dart';

/// Turns a free-form reply into a [ReplyIntent].
///
/// Two implementations exist: a fast, offline [RuleBasedIntentParser] and an
/// on-device LLM parser. The LLM is used when a model is installed, otherwise
/// the rule-based parser is the always-available fallback.
abstract class IntentParser {
  /// [confirmPhase] is true for the "did you do it?" follow-up call, which
  /// expects done / not-yet rather than do-now / postpone.
  Future<ReplyIntent> parse(String text, {required bool confirmPhase});
}
