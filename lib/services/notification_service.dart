import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      // FIX: Use .identifier instead of .name for version 5.0.2
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
      print("Timezone detection failed, defaulting to UTC: $e");
    }

    // 2. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
    );

    // 3. Request Permissions (Android 13+ & 14+)
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleDeadlineAlert(
    int id,
    String title,
    DateTime deadline,
    int minutesBefore,
  ) async {
    final reminderTime = deadline.subtract(Duration(minutes: minutesBefore));

    // Safety check for past times
    if (reminderTime.isBefore(DateTime.now())) {
      print("Reminder time is in the past, skipping schedule.");
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'bid_alarms',
      'Bid Alarms',
      channelDescription: 'Scheduled alarms for deadlines',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      'Bid Deadline Reminder!',
      'Project "$title" is due soon.',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(android: androidDetails),
      // --- MANDATORY FOR ANDROID 14 ---
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAlert(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // --- DIAGNOSTIC TEST (Use this to verify the fix) ---
  static Future<String> show10SecondTest() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(seconds: 10));

      const androidDetails = AndroidNotificationDetails(
        'timer_test',
        'Timer Test',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
      );

      await _notificationsPlugin.zonedSchedule(
        888,
        '10 Second Test',
        'The Exact Alarm system is FIXED!',
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      return "TEST SCHEDULED!\n\nWait 10 seconds.";
    } catch (e) {
      return "CRASH ERROR: $e";
    }
  }
}
