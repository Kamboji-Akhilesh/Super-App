import '../features/calendar/presentation/calendar_page.dart';
import '../features/calendar/presentation/event_alert_screen.dart';
import '../features/reminders/presentation/call_screen.dart';
import 'navigation.dart';

/// Routes a notification payload to the right screen. Payload formats:
///   `reminder:<id>`            → reminder call screen
///   `calendar:<id>:call`       → event/task call alert
///   `calendar:<id>:notif`      → open the calendar
void routeNotificationPayload(String payload) {
  final nav = navigatorKey.currentState;
  if (nav == null) return;

  final parts = payload.split(':');
  if (parts.isEmpty) return;

  switch (parts.first) {
    case 'reminder':
      final id = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (id != null) nav.pushNamed(CallScreen.route, arguments: id);
    case 'calendar':
      final id = parts.length > 1 ? int.tryParse(parts[1]) : null;
      if (id == null) return;
      final style = parts.length > 2 ? parts[2] : 'notif';
      if (style == 'call') {
        nav.pushNamed(EventAlertScreen.route, arguments: id);
      } else {
        nav.pushNamed(CalendarPage.route);
      }
  }
}
