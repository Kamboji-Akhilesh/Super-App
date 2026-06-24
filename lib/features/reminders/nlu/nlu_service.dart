import '../models/reply_intent.dart';
import '../services/gemma_model_service.dart';
import 'gemma_intent_parser.dart';
import 'rule_based_intent_parser.dart';

/// Routes reply interpretation to the on-device LLM when a model is installed,
/// otherwise to the rule-based parser.
class NluService {
  NluService({
    required RuleBasedIntentParser rules,
    required GemmaIntentParser gemma,
    required GemmaModelService modelService,
  })  : _rules = rules,
        _gemma = gemma,
        _modelService = modelService;

  final RuleBasedIntentParser _rules;
  final GemmaIntentParser _gemma;
  final GemmaModelService _modelService;

  Future<ReplyIntent> interpret(String text, {required bool confirmPhase}) {
    final parser = _modelService.isReady ? _gemma : _rules;
    return parser.parse(text, confirmPhase: confirmPhase);
  }

  /// Extracts an absolute time from "when?" answers (rule-based — time parsing
  /// is reliable and deterministic without an LLM).
  DateTime? parseWhen(String text) => _rules.extractTime(text.toLowerCase());

  /// Whether replies are currently interpreted by the on-device LLM.
  bool get usingAi => _modelService.isReady;
}
