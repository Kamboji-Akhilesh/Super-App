import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/reply_intent.dart';
import 'intent_parser.dart';
import 'rule_based_intent_parser.dart';

/// On-device LLM parser. Classifies the reply into one label; time extraction
/// for postponements reuses the (reliable) rule-based parser. Any failure or
/// ambiguous output falls back to rules so the call flow never dead-ends.
class GemmaIntentParser implements IntentParser {
  GemmaIntentParser(this._rules);

  final RuleBasedIntentParser _rules;
  InferenceModel? _model;

  @override
  Future<ReplyIntent> parse(String text, {required bool confirmPhase}) async {
    if (!FlutterGemma.hasActiveModel()) {
      return _rules.parse(text, confirmPhase: confirmPhase);
    }

    InferenceModelSession? session;
    try {
      _model ??= await FlutterGemma.getActiveModel(maxTokens: 256);
      session = await _model!.createSession(
        temperature: 0,
        topK: 1,
        systemInstruction: _systemPrompt(confirmPhase),
      );
      await session.addQueryChunk(
        Message.text(text: 'User reply: "$text"', isUser: true),
      );
      final raw = (await session.getResponse()).toUpperCase();
      final action = _actionFromLabel(raw, confirmPhase);
      if (action == ReplyAction.unknown) {
        return _rules.parse(text, confirmPhase: confirmPhase);
      }
      final when = action == ReplyAction.postpone
          ? _rules.extractTime(text.toLowerCase())
          : null;
      return ReplyIntent(action, postponeTo: when);
    } catch (_) {
      return _rules.parse(text, confirmPhase: confirmPhase);
    } finally {
      await session?.close();
    }
  }

  String _systemPrompt(bool confirmPhase) {
    final labels = confirmPhase
        ? 'DONE (they did the task), NOT_YET (not done), POSTPONE (do it at a later time)'
        : 'DO_NOW (they will do it now), DONE (already did it), POSTPONE (do it later)';
    return 'You label a short spoken reply to a task reminder. '
        'Respond with EXACTLY one of these labels and nothing else: $labels. '
        'If unsure, respond UNKNOWN.';
  }

  ReplyAction _actionFromLabel(String raw, bool confirmPhase) {
    if (raw.contains('POSTPONE')) return ReplyAction.postpone;
    if (raw.contains('NOT_YET') || raw.contains('NOT YET')) {
      return ReplyAction.notYet;
    }
    if (raw.contains('DO_NOW') || raw.contains('DO NOW')) {
      return ReplyAction.doItNow;
    }
    if (raw.contains('DONE')) return ReplyAction.done;
    return ReplyAction.unknown;
  }
}
