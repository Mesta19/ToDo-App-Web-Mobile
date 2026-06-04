// lib/services/notification_service_stub.dart
// Stub kosong — digunakan di web agar tidak import flutter_local_notifications
// yang tidak kompatibel dengan platform web.

class NotificationService {
  static Future<void> initialize() async {}
  static Future<void> scheduleTodoReminder(dynamic todo) async {}
  static Future<void> cancelTodoReminder(int id) async {}
  static Future<void> cancelAll() async {}
  static Future<void> showTestNotification() async {}
  static Future<void> scheduleTestNotificationWithDelay(int secondsDelay) async {}
  static Future<void> showDebugInfo() async {}
  static Future<List<dynamic>> getPendingNotifications() async => [];
}
