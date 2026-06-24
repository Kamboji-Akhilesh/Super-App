import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules exact-time alerts. Two styles:
///  - **call**: full-screen, max-importance, "call" category (a looping
///    ringtone is layered on top by the call screen itself).
///  - **notification**: a normal heads-up notification.
///
/// Payloads are opaque strings (e.g. `reminder:12`, `calendar:3:call`) so the
/// tap handler can route to the right screen.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _callChannel = 'reminder_calls';
  static const String _alertChannel = 'calendar_alerts';

  bool _initialised = false;

  Future<void> init({required void Function(String payload) onSelect}) async {
    if (_initialised) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(
          tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {/* fall back to UTC */}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null) onSelect(p);
      },
    );

    final android7 = _android;
    await android7?.createNotificationChannel(const AndroidNotificationChannel(
      _callChannel, 'Reminder & event calls',
      description: 'Full-screen call-style alerts',
      importance: Importance.max,
      playSound: true,
    ));
    await android7?.createNotificationChannel(const AndroidNotificationChannel(
      _alertChannel, 'Calendar alerts',
      description: 'Event and task notifications',
      importance: Importance.high,
      playSound: true,
    ));

    _initialised = true;
  }

  Future<void> requestPermissions() async {
    await _android?.requestNotificationsPermission();
    await _android?.requestExactAlarmsPermission();
  }

  /// Full-screen, call-style alert.
  Future<void> scheduleCall({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
  }) =>
      _schedule(
        id: id,
        when: when,
        title: title,
        body: body,
        payload: payload,
        channel: _callChannel,
        fullScreen: true,
        category: AndroidNotificationCategory.call,
        importance: Importance.max,
      );

  /// Normal heads-up notification alert.
  Future<void> scheduleNotification({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
  }) =>
      _schedule(
        id: id,
        when: when,
        title: title,
        body: body,
        payload: payload,
        channel: _alertChannel,
        fullScreen: false,
        category: AndroidNotificationCategory.reminder,
        importance: Importance.high,
      );

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
    required String channel,
    required bool fullScreen,
    required AndroidNotificationCategory category,
    required Importance importance,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channel == _callChannel ? 'Reminder & event calls' : 'Calendar alerts',
          importance: importance,
          priority: Priority.high,
          category: category,
          fullScreenIntent: fullScreen,
          visibility: NotificationVisibility.public,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Payload of the notification that launched the app (cold start), if any.
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
}
