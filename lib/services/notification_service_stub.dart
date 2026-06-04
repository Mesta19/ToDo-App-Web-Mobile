// lib/services/notification_service_stub.dart
//
// Implementasi NotificationService untuk platform WEB (dart:html).
// Menggunakan Web Notifications API bawaan browser.
//
// PENTING — Keterbatasan browser mobile (Android Chrome):
//   - requestPermission() HARUS dipanggil dari user gesture (tap/klik)
//   - Gunakan NotificationService.requestPermissionFromUserGesture() dari tombol UI
//   - Timer hanya berjalan saat tab aktif (tidak background)
//
// File ini HANYA dikompilasi saat build web.

import 'dart:async';
import 'dart:html' as html;

import '../models/todo_model.dart';

class NotificationService {
  static final Map<int, Timer> _timers = {};

  // Status apakah permission sudah diberikan
  static bool get isPermissionGranted =>
      _isSupported() && html.Notification.permission == 'granted';

  // Status apakah masih bisa diminta (belum denied)
  static bool get canRequestPermission =>
      _isSupported() && html.Notification.permission != 'denied';

  /// Inisialisasi — TIDAK minta permission otomatis (blocked di mobile).
  /// Permission hanya diminta saat user tap tombol (lihat [requestPermissionFromUserGesture]).
  static Future<void> initialize() async {
    if (!_isSupported()) {
      print('[WebNotification] Browser tidak mendukung Web Notifications API');
      return;
    }
    print('[WebNotification] Status permission: ${html.Notification.permission}');
    // Tidak auto-request — harus dari user gesture
  }

  /// Minta izin notifikasi dari browser.
  /// WAJIB dipanggil dari callback user gesture (onPressed, onTap, dll.).
  /// Mengembalikan true jika izin diberikan, false jika ditolak.
  static Future<bool> requestPermissionFromUserGesture() async {
    if (!_isSupported()) return false;
    if (isPermissionGranted) return true;

    try {
      final result = await html.Notification.requestPermission();
      print('[WebNotification] Permission result: $result');
      return result == 'granted';
    } catch (e) {
      print('[WebNotification] Error requesting permission: $e');
      return false;
    }
  }

  /// Jadwalkan reminder untuk todo — menggunakan dart:async Timer.
  static Future<void> scheduleTodoReminder(Todo todo) async {
    if (todo.isDone) return;

    final now = DateTime.now();
    if (todo.reminderAt.isBefore(now)) {
      print('[WebNotification] Skip - reminder sudah lewat: ${todo.reminderAt}');
      return;
    }

    await cancelTodoReminder(todo.id);

    final delay = todo.reminderAt.difference(now);
    print('[WebNotification] Reminder todo ${todo.id} dijadwalkan dalam ${delay.inMinutes} menit');

    _timers[todo.id] = Timer(delay, () {
      _showNotification(
        title: '⏰ Waktunya: ${todo.title}',
        body: todo.description.isNotEmpty
            ? todo.description
            : 'Todo perlu dikerjakan sekarang!',
        tag: 'todo-${todo.id}',
      );
      _timers.remove(todo.id);
    });
  }

  /// Batalkan reminder untuk todo tertentu.
  static Future<void> cancelTodoReminder(int id) async {
    final timer = _timers.remove(id);
    if (timer != null) {
      timer.cancel();
      print('[WebNotification] Timer todo $id dibatalkan');
    }
  }

  /// Batalkan semua reminder aktif.
  static Future<void> cancelAll() async {
    for (final entry in _timers.entries) {
      entry.value.cancel();
    }
    _timers.clear();
    print('[WebNotification] Semua timer web dibatalkan');
  }

  /// Tampilkan notifikasi test segera.
  static Future<void> showTestNotification() async {
    _showNotification(
      title: '✅ Test Notifikasi Web',
      body: 'Notifikasi browser berhasil aktif!',
      tag: 'test-9999',
    );
  }

  static Future<void> scheduleTestNotificationWithDelay(int secondsDelay) async {
    Timer(Duration(seconds: secondsDelay), () {
      _showNotification(
        title: '🧪 Test Scheduled',
        body: 'Muncul setelah $secondsDelay detik',
        tag: 'test-9997',
      );
    });
  }

  static Future<void> showDebugInfo() async {
    print('[WebNotification] === DEBUG INFO ===');
    print('[WebNotification] Support: ${_isSupported()}');
    print('[WebNotification] Permission: ${html.Notification.permission}');
    print('[WebNotification] Active timers: ${_timers.length}');
    for (final id in _timers.keys) {
      print('[WebNotification]   - Todo ID: $id');
    }
    print('[WebNotification] === END DEBUG ===');
  }

  static Future<List<dynamic>> getPendingNotifications() async {
    return _timers.keys.toList();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static void _showNotification({
    required String title,
    required String body,
    required String tag,
  }) {
    if (!_isSupported()) return;

    if (!isPermissionGranted) {
      print('[WebNotification] Permission belum diberikan — notifikasi tidak tampil');
      return;
    }

    try {
      html.Notification(title, body: body, tag: tag);
      print('[WebNotification] ✓ Notifikasi ditampilkan: $title');
    } catch (e) {
      print('[WebNotification] ✗ Error: $e');
    }
  }

  static bool _isSupported() {
    try {
      return html.Notification.supported;
    } catch (_) {
      return false;
    }
  }
}
