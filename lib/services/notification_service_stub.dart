// lib/services/notification_service_stub.dart
//
// Digunakan di PLATFORM WEB sebagai pengganti notification_service.dart
// (yang tidak bisa dikompilasi untuk web karena flutter_local_notifications).
//
// Semua pemanggilan didelegasikan ke WebNotificationService yang menggunakan
// Timer + in-display popup overlay — tanpa sistem notifikasi OS apapun.

import '../models/todo_model.dart';
import 'web_notification_service.dart';

class NotificationService {
  /// Tidak ada yang perlu diinisialisasi di web
  static Future<void> initialize() async {}

  /// Jadwalkan popup reminder via WebNotificationService
  static Future<void> scheduleTodoReminder(Todo todo) async {
    WebNotificationService.scheduleTodoReminder(todo);
  }

  /// Batalkan timer reminder untuk todo tertentu
  static Future<void> cancelTodoReminder(int id) async {
    WebNotificationService.cancelTodoReminder(id);
  }

  /// Batalkan semua timer reminder aktif
  static Future<void> cancelAll() async {
    WebNotificationService.cancelAll();
  }

  /// Tidak relevan di web
  static Future<void> showTestNotification() async {}

  /// Tidak relevan di web
  static Future<void> scheduleTestNotificationWithDelay(int secondsDelay) async {}

  /// Tidak relevan di web
  static Future<void> showDebugInfo() async {
    print('[WebStub] Aktif timers: ${WebNotificationService.activeCount}');
  }

  /// Tidak relevan di web
  static Future<List<dynamic>> getPendingNotifications() async => [];
}
