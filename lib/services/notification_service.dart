// lib/services/notification_service.dart

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:auto_start_flutter/auto_start_flutter.dart';

import '../models/todo_model.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;
  static bool _initialized = false;
  static const String _scheduledNotificationsKey = 'scheduled_notifications';

  /// Inisialisasi — otomatis skip jika berjalan di web.
  static Future<void> initialize() async {
    if (kIsWeb) return; // Web tidak support notifikasi lokal
    if (_initialized) return;

    _plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    await _plugin!.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('[NotificationService] Notification tapped: ${response.payload}');
      },
    );

    await _configureLocalTimeZone();
    await _requestPermissions();
    await _rescheduleStoredNotifications();

    _initialized = true;
    print('[NotificationService] Initialized successfully');
    print('[NotificationService] Timezone: ${tz.local.name}');
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb || _plugin == null) return [];
    try {
      return await _plugin!.pendingNotificationRequests();
    } catch (e) {
      print('[NotificationService] Error getting pending notifications: $e');
      return [];
    }
  }

  static Future<void> showDebugInfo() async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      print('[NotificationService] Local timezone set: ${timeZoneInfo.identifier}');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('[NotificationService] Fallback timezone to UTC: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb || _plugin == null) return;
    try {
      final android = _plugin!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        print('[NotificationService] Android permission: $granted');

        // ✅ Minta exact alarm permission (Android 12+)
        await android.requestExactAlarmsPermission();
        print('[NotificationService] Exact alarm permission requested');
      }
      final ios = _plugin!.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        await ios.requestPermissions(alert: true, sound: true, badge: true);
      }
    } catch (e) {
      print('[NotificationService] Permission request error: $e');
    }

    // ✅ Minta pengecualian battery optimization (agar alarm jalan saat app di-close)
    await _requestBatteryOptimizationExemption();

    // ✅ Minta izin Autostart khusus untuk vendor HP Tiongkok (Xiaomi, Oppo, Vivo, dll)
    await _requestAutoStartPermission();
  }

  /// Membuka halaman pengaturan Autostart/Mulai Otomatis untuk merek HP tertentu
  /// agar sistem operasi tidak mematikan notifikasi paksa.
  static Future<void> _requestAutoStartPermission() async {
    if (kIsWeb) return;
    try {
      final isAvailable = await (isAutoStartAvailable as Future<bool?>);
      if (isAvailable == true) {
        await getAutoStartPermission();
        print('[NotificationService] Requested auto-start permission');
      }
    } catch (e) {
      print('[NotificationService] Auto-start permission request failed: $e');
    }
  }

  /// Minta agar app dikecualikan dari battery optimization Android.
  /// Ini diperlukan agar alarm tetap terjadwal walau app di-swipe close.
  static Future<void> _requestBatteryOptimizationExemption() async {
    if (kIsWeb) return;
    try {
      // Cek platform via dart:io agar tidak crash di web
      // Gunakan method channel Android untuk cek dan minta exemption
      const channel = MethodChannel('com.tws_project/battery');
      await channel.invokeMethod('requestIgnoreBatteryOptimizations');
      print('[NotificationService] Battery optimization exemption requested');
    } catch (e) {
      // Tidak fatal — notifikasi tetap bisa jalan meski permission ini tidak ada,
      // hanya lebih rentan di-kill oleh Android battery optimization
      print('[NotificationService] Battery opt exemption not available: $e');
    }
  }

  static Future<void> _saveScheduledNotification(int todoId, DateTime reminderAt) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduled = prefs.getStringList(_scheduledNotificationsKey) ?? [];
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
    if (kIsWeb) return;
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
    if (kIsWeb || _plugin == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduled = prefs.getStringList(_scheduledNotificationsKey) ?? [];
      final List<String> toRemove = [];

      print('[NotificationService] Found ${scheduled.length} stored notifications');

      for (final entry in scheduled) {
        try {
          final colonIndex = entry.indexOf(':');
          if (colonIndex == -1) {
            toRemove.add(entry);
            continue;
          }
          final todoId = int.parse(entry.substring(0, colonIndex));
          final reminderAt = DateTime.parse(entry.substring(colonIndex + 1));

          if (reminderAt.isBefore(DateTime.now())) {
            print('[NotificationService] Skipping past reminder for todo $todoId');
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

      if (toRemove.isNotEmpty) {
        scheduled.removeWhere((entry) => toRemove.contains(entry));
        await prefs.setStringList(_scheduledNotificationsKey, scheduled);
        print('[NotificationService] Cleaned up ${toRemove.length} stale entries');
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
    if (kIsWeb) return;
    if (todo.isDone) return;

    final now = DateTime.now();
    if (todo.reminderAt.isBefore(now)) {
      print('[NotificationService] Skip - reminder already passed: ${todo.reminderAt}');
      return;
    }

    print('[NotificationService] Scheduling reminder for todo ${todo.id}');
    await cancelTodoReminder(todo.id);

    try {
      final tzDateTime = tz.TZDateTime.from(todo.reminderAt, tz.local);
      await _scheduleWithFallback(
        todo.id,
        'Waktunya: ${todo.title}',
        todo.description.isNotEmpty ? todo.description : 'Todo perlu dikerjakan sekarang.',
        tzDateTime,
      );
      await _saveScheduledNotification(todo.id, todo.reminderAt);
      print('[NotificationService] ✓ Scheduled todo ${todo.id} at $tzDateTime');
    } catch (e) {
      print('[NotificationService] ✗ Error scheduling reminder: $e');
    }
  }

  static Future<void> _scheduleWithFallback(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime,
  ) async {
    if (kIsWeb || _plugin == null) return;
    try {
      final delay = scheduledTime.difference(DateTime.now());
      if (delay.isNegative) return;

      try {
        await _plugin!.zonedSchedule(
          id, title, body, scheduledTime, _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
        print('[NotificationService] ✓ Scheduled with exact mode');
      } catch (e) {
        await _plugin!.zonedSchedule(
          id, title, body, scheduledTime, _details(),
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
    if (kIsWeb || _plugin == null) return;
    try {
      await _plugin!.cancel(id);
      await _removeScheduledNotification(id);
      print('[NotificationService] Notifikasi untuk todo $id dibatalkan');
    } catch (e) {
      print('[NotificationService] Error cancel reminder todo $id: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || _plugin == null) return;
    try {
      await _plugin!.cancelAll();
      print('[NotificationService] Semua notifikasi dibatalkan');
    } catch (e) {
      print('[NotificationService] Error cancel all: $e');
    }
  }

  static Future<void> showTestNotification() async {
    if (kIsWeb || _plugin == null) return;
    try {
      await _plugin!.show(
        9999,
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

  static Future<void> scheduleTestNotificationWithDelay(int secondsDelay) async {
    if (kIsWeb) return;
    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: secondsDelay));
      final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
      await _scheduleWithFallback(
        9997,
        'Debug: Test Scheduled Notif',
        'Ini seharusnya muncul dalam $secondsDelay detik',
        tzDateTime,
      );
      print('[NotificationService] ✓ Test notification scheduled for $secondsDelay seconds');
    } catch (e) {
      print('[NotificationService] ✗ Error scheduling test: $e');
    }
  }
}
