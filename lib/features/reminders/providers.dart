import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'controllers/reminders_controller.dart';
import 'controllers/reminder_settings_controller.dart';
import 'data/reminder_store.dart';
import 'models/reminder.dart';
import 'models/reminder_settings.dart';
import 'nlu/gemma_intent_parser.dart';
import 'nlu/nlu_service.dart';
import 'nlu/rule_based_intent_parser.dart';
import 'services/gemma_model_service.dart';
import 'services/notification_service.dart';
import 'services/ringtone_service.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';

final reminderStoreProvider = Provider<ReminderStore>(
  (ref) => ReminderStore(ref.watch(sharedPreferencesProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(service.cancel);
  return service;
});

final ringtoneServiceProvider = Provider<RingtoneService>((ref) {
  final service = RingtoneService();
  ref.onDispose(service.stop);
  return service;
});

final gemmaModelServiceProvider = Provider<GemmaModelService>(
  (ref) => GemmaModelService(ref.watch(sharedPreferencesProvider)),
);

const _ruleBasedParser = RuleBasedIntentParser();

final nluServiceProvider = Provider<NluService>(
  (ref) => NluService(
    rules: _ruleBasedParser,
    gemma: GemmaIntentParser(_ruleBasedParser),
    modelService: ref.watch(gemmaModelServiceProvider),
  ),
);

final remindersControllerProvider =
    NotifierProvider<RemindersController, List<Reminder>>(
  RemindersController.new,
);

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
  ReminderSettingsController.new,
);
