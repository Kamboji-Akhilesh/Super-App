import 'package:flutter/material.dart';
import 'package:super_app/l10n/app_localizations.dart';

import 'core/navigation.dart';
import 'core/notification_router.dart';
import 'features/calendar/presentation/calendar_page.dart';
import 'features/calendar/presentation/entry_edit_page.dart';
import 'features/calendar/presentation/event_alert_screen.dart';
import 'features/currency/presentation/currency_home_page.dart';
import 'features/notes/presentation/note_edit_page.dart';
import 'features/notes/presentation/notes_page.dart';
import 'features/reminders/presentation/call_screen.dart';
import 'features/reminders/presentation/reminder_settings_page.dart';
import 'home/home_page.dart';
import 'theme/app_theme.dart';

class SuperApp extends StatefulWidget {
  const SuperApp({super.key, this.launchPayload});

  /// If a notification cold-started the app, its payload is routed once the
  /// first frame is ready.
  final String? launchPayload;

  @override
  State<SuperApp> createState() => _SuperAppState();
}

class _SuperAppState extends State<SuperApp> {
  @override
  void initState() {
    super.initState();
    final payload = widget.launchPayload;
    if (payload != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => routeNotificationPayload(payload),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      initialRoute: HomePage.route,
      routes: {
        HomePage.route: (_) => const HomePage(),
        CurrencyHomePage.route: (_) => const CurrencyHomePage(),
        CalendarPage.route: (_) => const CalendarPage(),
        NotesPage.route: (_) => const NotesPage(),
        ReminderSettingsPage.route: (_) => const ReminderSettingsPage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case NoteEditPage.route:
            final args = settings.arguments as NoteEditArgs?;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => NoteEditPage(noteId: args?.noteId),
            );
          case EntryEditPage.route:
            final args = settings.arguments as EntryEditArgs?;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => EntryEditPage(
                entryId: args?.entryId,
                initialDay: args?.initialDay,
              ),
            );
          case EventAlertScreen.route:
            return MaterialPageRoute(
              settings: settings,
              fullscreenDialog: true,
              builder: (_) =>
                  EventAlertScreen(entryId: settings.arguments as int),
            );
          case CallScreen.route:
            return MaterialPageRoute(
              settings: settings,
              fullscreenDialog: true,
              builder: (_) =>
                  CallScreen(reminderId: settings.arguments as int),
            );
        }
        return null;
      },
    );
  }
}
