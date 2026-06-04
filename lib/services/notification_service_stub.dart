// lib/services/notification_service_stub.dart
//
// Implementasi NotificationService untuk platform WEB.
// Menggunakan Web Notifications API (dart:html) bawaan browser.
//
// Keterbatasan web:
//   - Notifikasi hanya tampil jika tab browser sedang aktif/terbuka
//   - Pengguna harus klik "Allow" saat browser meminta izin notifikasi
//
// File ini HANYA dikompilasi saat build web (dipilih oleh notification_helper.dart).

import 'dart:async';
import 'dart:html' as html;

import '../models/todo_model.dart';

class NotificationService {
  // Menyimpan semua timer aktif agar bisa dibatalkan
  // key = todo.id, value = Timer yang akan trigger notifikasi
  static final Map<int, Timer> _timers = {};

  /// Inisialisasi — minta izin notifikasi dari browser.
  static Future<void> initialize() async {
    try {
      // Cek apakah browser mendukung Notification API
      if (!_isSupported()) {
        print('[WebNotification] Browser tidak mendukung Web Notifications');
        return;
      }

      final permission = html.Notification.permission;
      if (permission == 'granted') {
        print('[WebNotification] Izin notifikasi sudah diberikan');
        return;
      }

      if (permission != 'denied') {
        // Minta izin ke pengguna (muncul popup browser "Allow/Block")
        final result = await html.Notification.requestPermission();
        if (result == 'granted') {
          print('[WebNotification] Izin notifikasi diberikan oleh pengguna');
        } else {
          print('[WebNotification] Izin notifikasi ditolak: $result');
        }
      }
    } catch (e) {
      print('[WebNotification] Error saat inisialisasi: $e');
    }
  }

  /// Jadwalkan reminder untuk todo — menggunakan Timer browser.
  static Future<void> scheduleTodoReminder(Todo todo) async {
    if (todo.isDone) return;

    final now = DateTime.now();
    if (todo.reminderAt.isBefore(now)) {
      print('[WebNotification] Skip - reminder sudah lewat: ${todo.reminderAt}');
      return;
    }

    // Batalkan timer lama jika ada
    await cancelTodoReminder(todo.id);

    final delay = todo.reminderAt.difference(now);
    print('[WebNotification] Menjadwalkan reminder todo ${todo.id} dalam ${delay.inMinutes} menit');

    _timers[todo.id] = Timer(delay, () {
      _showNotification(
        title: '⏰ Waktunya: ${todo.title}',
        body: todo.description.isNotEmpty
            ? todo.description
            : 'Todo perlu dikerjakan sekarang!',
        todoId: todo.id,
      );
      _timers.remove(todo.id);
    });
  }

  /// Batalkan reminder untuk todo tertentu.
  static Future<void> cancelTodoReminder(int id) async {
    final timer = _timers[id];
    if (timer != null) {
      timer.cancel();
      _timers.remove(id);
      print('[WebNotification] Timer todo $id dibatalkan');
    }
  }

  /// Batalkan semua reminder yang sedang aktif.
  static Future<void> cancelAll() async {
    for (final entry in _timers.entries) {
      entry.value.cancel();
      print('[WebNotification] Timer todo ${entry.key} dibatalkan');
    }
    _timers.clear();
    print('[WebNotification] Semua timer dibatalkan');
  }

  /// Tampilkan notifikasi test segera.
  static Future<void> showTestNotification() async {
    _showNotification(
      title: '✅ Test Notifikasi Web',
      body: 'Jika kamu melihat ini, Web Notification berfungsi!',
      todoId: 9999,
    );
  }

  /// Test dengan delay (dalam detik).
  static Future<void> scheduleTestNotificationWithDelay(int secondsDelay) async {
    print('[WebNotification] Menjadwalkan test notifikasi dalam $secondsDelay detik');
    Timer(Duration(seconds: secondsDelay), () {
      _showNotification(
        title: '🧪 Test Scheduled',
        body: 'Ini muncul setelah $secondsDelay detik',
        todoId: 9997,
      );
    });
  }

  /// Debug info — tampilkan status di console.
  static Future<void> showDebugInfo() async {
    print('[WebNotification] === DEBUG INFO ===');
    print('[WebNotification] Browser support: ${_isSupported()}');
    print('[WebNotification] Permission: ${html.Notification.permission}');
    print('[WebNotification] Active timers: ${_timers.length}');
    for (final id in _timers.keys) {
      print('[WebNotification]   - Todo ID: $id');
    }
    print('[WebNotification] === END DEBUG ===');
  }

  /// Daftar timer aktif (untuk keperluan debugging).
  static Future<List<dynamic>> getPendingNotifications() async {
    return _timers.keys.toList();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  /// Tampilkan browser notification.
  static void _showNotification({
    required String title,
    required String body,
    required int todoId,
  }) {
    try {
      if (!_isSupported()) {
        print('[WebNotification] Browser tidak support notifikasi');
        return;
      }

      if (html.Notification.permission != 'granted') {
        print('[WebNotification] Izin belum diberikan — notifikasi tidak ditampilkan');
        // Coba minta izin lagi lalu tampilkan
        html.Notification.requestPermission().then((permission) {
          if (permission == 'granted') {
            html.Notification(title, body: body, tag: 'todo-$todoId');
          }
        });
        return;
      }

      html.Notification(
        title,
        body: body,
        tag: 'todo-$todoId', // tag mencegah duplikasi notifikasi yang sama
      );
      print('[WebNotification] ✓ Notifikasi ditampilkan: $title');
    } catch (e) {
      print('[WebNotification] ✗ Error menampilkan notifikasi: $e');
    }
  }

  /// Cek apakah browser mendukung Web Notifications API.
  static bool _isSupported() {
    try {
      return html.Notification.supported;
    } catch (_) {
      return false;
    }
  }
}
