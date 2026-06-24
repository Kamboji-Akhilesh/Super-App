import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notification_router.dart';
import 'core/providers.dart';
import 'features/reminders/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore any previously installed on-device LLM so reply interpretation can
  // use it (falls back to the rule-based parser when none is installed).
  await FlutterGemma.initialize();

  // Resolve persistent storage once and inject it into the provider graph.
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialise the alert system. Tapping an alert routes to the right screen
  // (reminder call / event call / calendar) via the payload.
  final notifications = container.read(notificationServiceProvider);
  await notifications.init(onSelect: routeNotificationPayload);
  await notifications.requestPermissions();

  // If an alert cold-started the app, route to it after launch.
  final launchPayload = await notifications.launchPayload();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: SuperApp(launchPayload: launchPayload),
    ),
  );
}
