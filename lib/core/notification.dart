import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/models.dart';

/// Local notifications: smart reminders, streaks, weekly review.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_tzName()));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(settings: const InitializationSettings(android: android, iOS: ios));
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    _initialized = true;
  }

  String _tzName() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inMinutes;
    final sign = offset < 0 ? '-' : '+';
    final h = (offset.abs() ~/ 60).toString().padLeft(2, '0');
    final m = (offset.abs() % 60).toString().padLeft(2, '0');
    final fixed = offset.abs() % 60 == 0 ? '' : ':$m';
    return 'Etc/GMT$sign$h$fixed';
  }

  tz.TZDateTime _at(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  Future<void> configure(AppSettings s) async {
    if (!_initialized) await init();
    await _plugin.cancelAll();

    if (!s.notificationsEnabled) return;

    final androidDetails = AndroidNotificationDetails(
      'reforge_reminders',
      'Reforge Reminders',
      channelDescription: 'Smart reminders that keep your quests on track',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    final details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    Future<void> daily(int id, String title, String body, int hour, int minute) async {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _at(hour, minute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // Morning motivation + main quest
    await daily(101, '☀️ Good Morning, Champion!', 'Today\'s main quest is waiting. Small wins stack into a transformation.', 8, 0);
    // Water nudges (spread through the day)
    var waterId = 200;
    for (var h = s.waterReminderHour; h <= 21; h += 3) {
      await daily(waterId++, '💧 Hydration Quest', 'Time to drink water. +5 XP per glass!', h, 0);
    }
    // Protein low
    await daily(301, '🍗 Protein is low today', 'Stack protein: eggs, chicken, daal or a shake.', 15, 0);
    // Steps
    await daily(302, '🏃 Go for a walk', 'Every 1,000 steps is progress. Future You is watching.', 17, 30);
    // Workout reminder
    await daily(303, '💪 Workout starts soon', 'Your home workout waits. 20 minutes = big XP.', s.workoutReminderHour, s.workoutReminderMinute);
    // Evening streak protection
    await daily(304, '🔥 Protect your streak', 'You\'re close to a milestone. One more small win today.', 20, 30);
    // Sleep reminder
    await daily(305, '🌙 Sleep reminder', 'Sleep is part of the game. Winding down now wins tomorrow.', s.sleepReminderHour, s.sleepReminderMinute);
    // Weekly review
    await daily(306, '📊 Weekly Review', 'Let\'s see what improved this week in Reforge.', 18, 0);
  }

  Future<void> cancelAll() async {
    if (_initialized) await _plugin.cancelAll();
  }
}
