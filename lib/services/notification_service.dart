// lib/services/notification_service.dart

import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/todo_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static const String _scheduledNotificationsKey = 'scheduled_notifications';

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('[NotificationService] Notification tapped: ${response.payload}');
      },
    );

    await _configureLocalTimeZone();
    await _requestPermissions();

    // Re-schedule notifications yang tersimpan saat startup
    await _rescheduleStoredNotifications();

    _initialized = true;
    print('[NotificationService] Initialized successfully');
    print('[NotificationService] Timezone: ${tz.local.name}');

    // DIHAPUS: _testNotification() — ID 0 bisa menimpa todo ID yang valid
  }

  // Get pending notifications untuk debugging
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      print('[NotificationService] Error getting pending notifications: $e');
      return [];
    }
  }

  // Show debug info
  static Future<void> showDebugInfo() async {
    try {
      final pending = await getPendingNotifications();
      print('[NotificationService] === DEBUG INFO ===');
      print('[NotificationService] Current time: ${DateTime.now()}');
      print('[NotificationService] Local timezone: ${tz.local.name}');
      print('[NotificationService] Pending notifications: ${pending.length}');
      for (final p in pending) {
        print('[NotificationService]   - ID: ${p.id}, Title: ${p.title}');
      }
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_scheduledNotificationsKey) ?? [];
      print('[NotificationService] Saved in prefs: ${saved.length}');
      for (final s in saved) {
        print('[NotificationService]   - $s');
      }
      print('[NotificationService] === END DEBUG ===');
    } catch (e) {
      print('[NotificationService] Error showing debug: $e');
    }
  }

  static Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      print(
          '[NotificationService] Local timezone set: ${timeZoneInfo.identifier}');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('[NotificationService] Fallback timezone to UTC: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        print('[NotificationService] Android permission: $granted');
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        await ios.requestPermissions(alert: true, sound: true, badge: true);
      }
    } catch (e) {
      print('[NotificationService] Permission request error: $e');
    }
  }

  static Future<void> _saveScheduledNotification(
      int todoId, DateTime reminderAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduled = prefs.getStringList(_scheduledNotificationsKey) ?? [];

      // Format: "todoId:reminderAt" — gunakan separator yang aman
      final entry = '$todoId:${reminderAt.toIso8601String()}';
      if (!scheduled.contains(entry)) {
        scheduled.add(entry);
        await prefs.setStringList(_scheduledNotificationsKey, scheduled);
        print('[NotificationService] Saved notification for todo $todoId');
      }
    } catch (e) {
      print('[NotificationService] Error saving notification: $e');
    }
  }

  static Future<void> _removeScheduledNotification(int todoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduled = prefs.getStringList(_scheduledNotificationsKey) ?? [];

      scheduled.removeWhere((entry) => entry.startsWith('$todoId:'));
      await prefs.setStringList(_scheduledNotificationsKey, scheduled);
      print('[NotificationService] Removed notification for todo $todoId');
    } catch (e) {
      print('[NotificationService] Error removing notification: $e');
    }
  }

  static Future<void> _rescheduleStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduled = prefs.getStringList(_scheduledNotificationsKey) ?? [];
      final List<String> toRemove = [];

      print(
          '[NotificationService] Found ${scheduled.length} stored notifications');

      for (final entry in scheduled) {
        try {
          // FIX: ISO 8601 mengandung banyak ':', jadi split hanya pada ':' pertama
          final colonIndex = entry.indexOf(':');
          if (colonIndex == -1) {
            print(
                '[NotificationService] Invalid entry format, skipping: $entry');
            toRemove.add(entry);
            continue;
          }

          final todoId = int.parse(entry.substring(0, colonIndex));
          final reminderAt = DateTime.parse(entry.substring(colonIndex + 1));

          // Skip jika sudah lewat waktu
          if (reminderAt.isBefore(DateTime.now())) {
            print(
                '[NotificationService] Skipping past reminder for todo $todoId');
            toRemove.add(entry);
            continue;
          }

          final tzDateTime = tz.TZDateTime.from(reminderAt, tz.local);
          await _scheduleWithFallback(
            todoId,
            'Pengingat Todo',
            'Todo perlu dikerjakan sekarang',
            tzDateTime,
          );
          print('[NotificationService] Re-scheduled todo $todoId');
        } catch (e) {
          print('[NotificationService] Error re-scheduling entry "$entry": $e');
          toRemove.add(entry);
        }
      }

      // Hapus semua entries yang expired atau invalid sekaligus
      if (toRemove.isNotEmpty) {
        scheduled.removeWhere((entry) => toRemove.contains(entry));
        await prefs.setStringList(_scheduledNotificationsKey, scheduled);
        print(
            '[NotificationService] Cleaned up ${toRemove.length} stale entries');
      }
    } catch (e) {
      print('[NotificationService] Error reschedule stored notifications: $e');
    }
  }

  static NotificationDetails _details() => NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminder_alarm',
          'Todo Reminder (Alarm)',
          channelDescription: 'Pengingat waktu todo dengan alarm',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('alarm_todo'),
          vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]),
          enableVibration: true,
          fullScreenIntent: true,
          showWhen: true,
          ongoing: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          badgeNumber: 1,
        ),
      );

  static Future<void> scheduleTodoReminder(Todo todo) async {
    if (todo.isDone) return;

    final now = DateTime.now();
    if (todo.reminderAt.isBefore(now)) {
      print(
          '[NotificationService] Skip - reminder already passed: ${todo.reminderAt}');
      return;
    }

    print('[NotificationService] === SCHEDULE TODO REMINDER ===');
    print('[NotificationService] Todo ID: ${todo.id}, Title: ${todo.title}');
    print('[NotificationService] Current time (local): $now');
    print('[NotificationService] Current time (UTC): ${now.toUtc()}');
    print('[NotificationService] Reminder time (local): ${todo.reminderAt}');
    print(
        '[NotificationService] Reminder time (UTC): ${todo.reminderAt.toUtc()}');
    print('[NotificationService] Timezone: ${tz.local.name}');

    await cancelTodoReminder(todo.id);

    try {
      final tzDateTime = tz.TZDateTime.from(todo.reminderAt, tz.local);
      final timeUntilReminder = todo.reminderAt.difference(now);

      print('[NotificationService] Converted TZ DateTime: $tzDateTime');
      print('[NotificationService] Time until reminder: $timeUntilReminder');

      await _scheduleWithFallback(
        todo.id,
        'Waktunya: ${todo.title}',
        todo.description.isNotEmpty
            ? todo.description
            : 'Todo perlu dikerjakan sekarang.',
        tzDateTime,
      );

      await _saveScheduledNotification(todo.id, todo.reminderAt);

      print('[NotificationService] ✓ Scheduled todo ${todo.id} at $tzDateTime');
    } catch (e) {
      print('[NotificationService] ✗ Error scheduling reminder: $e');
      print('[NotificationService] Stack trace: ${StackTrace.current}');
    }
  }

  static Future<void> _scheduleWithFallback(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime,
  ) async {
    try {
      final now = DateTime.now();
      final delay = scheduledTime.difference(now);

      print('[NotificationService] Now: $now');
      print('[NotificationService] ScheduledTime: $scheduledTime');
      print('[NotificationService] Delay: $delay');

      if (delay.isNegative || delay.inSeconds < 0) {
        print('[NotificationService] ✗ Scheduled time already passed');
        return;
      }

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
        print('[NotificationService] ✓ Scheduled with exact mode');
      } catch (e) {
        // Fallback ke inexact jika exact tidak diizinkan
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          _details(),
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
        print('[NotificationService] ✓ Scheduled with inexact fallback: $e');
      }
    } catch (e) {
      print('[NotificationService] ✗ Scheduling failed: $e');
      rethrow;
    }
  }

  static Future<void> cancelTodoReminder(int id) async {
    try {
      await _plugin.cancel(id);
      await _removeScheduledNotification(id);
      print('[NotificationService] Notifikasi untuk todo $id dibatalkan');
    } catch (e) {
      print('[NotificationService] Error cancel reminder todo $id: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      print('[NotificationService] Semua notifikasi dibatalkan');
    } catch (e) {
      print('[NotificationService] Error cancel all: $e');
    }
  }

  // Public method untuk test immediate notification
  static Future<void> showTestNotification() async {
    try {
      await _plugin.show(
        9999, // FIX: ID aman, jauh dari range todo ID normal
        'Test Notification',
        'Jika Anda melihat ini, notification system bekerja!',
        _details(),
        payload: 'test',
      );
      print('[NotificationService] Test notification shown');
    } catch (e) {
      print('[NotificationService] Error showing test notification: $e');
    }
  }

  // Test scheduled notification dengan delay tertentu (untuk debugging)
  static Future<void> scheduleTestNotificationWithDelay(
      int secondsDelay) async {
    try {
      final now = DateTime.now();
      final scheduledTime = now.add(Duration(seconds: secondsDelay));
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

      print('[NotificationService] === SCHEDULE TEST NOTIFICATION ===');
      print('[NotificationService] Current time (local): $now');
      print(
          '[NotificationService] Current time (UTC): ${DateTime.now().toUtc()}');
      print('[NotificationService] Scheduled time (local): $scheduledTime');
      print(
          '[NotificationService] Scheduled time (UTC): ${scheduledTime.toUtc()}');
      print('[NotificationService] TZ DateTime: $tzDateTime');
      print('[NotificationService] Delay: $secondsDelay seconds');
      print('[NotificationService] Timezone: ${tz.local.name}');

      await _scheduleWithFallback(
        9997, // FIX: ID aman untuk test
        'Debug: Test Scheduled Notif',
        'Ini seharusnya muncul dalam $secondsDelay detik',
        tzDateTime,
      );
      print(
          '[NotificationService] ✓ Test notification scheduled for $secondsDelay seconds');
    } catch (e) {
      print('[NotificationService] ✗ Error scheduling test: $e');
      print('[NotificationService] Stack trace: ${StackTrace.current}');
    }
  }
}
