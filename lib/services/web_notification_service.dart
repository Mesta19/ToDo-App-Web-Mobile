// lib/services/web_notification_service.dart
//
// Notifikasi in-display khusus versi WEB.
// Menggunakan dart:async Timer untuk menjadwalkan popup,
// dan Stream untuk mengirim event ke widget overlay.
// Tidak menggunakan flutter_local_notifications sama sekali.

import 'dart:async';
import '../models/todo_model.dart';

/// Data yang dibawa saat notifikasi di-trigger
class WebNotificationEvent {
  final int todoId;
  final String title;
  final String description;
  final DateTime scheduledAt;

  const WebNotificationEvent({
    required this.todoId,
    required this.title,
    required this.description,
    required this.scheduledAt,
  });
}

class WebNotificationService {
  // ── Stream controller — emit event saat reminder tiba ──────────────────────
  static final StreamController<WebNotificationEvent> _controller =
      StreamController<WebNotificationEvent>.broadcast();

  /// Dengarkan stream ini dari widget overlay untuk menampilkan popup
  static Stream<WebNotificationEvent> get stream => _controller.stream;

  // ── Map untuk menyimpan aktif timers per todo ID ────────────────────────────
  static final Map<int, Timer> _timers = {};

  // ── Jadwalkan reminder untuk satu todo ─────────────────────────────────────
  static void scheduleTodoReminder(Todo todo) {
    if (todo.isDone) return;

    final now = DateTime.now();
    final delay = todo.reminderAt.difference(now);

    // Jangan jadwalkan kalau waktu sudah lewat
    if (delay.isNegative || delay.inSeconds <= 0) {
      print('[WebNotif] Skip — reminder sudah lewat: ${todo.title}');
      return;
    }

    // Batalkan timer sebelumnya untuk todo yang sama (jika ada)
    cancelTodoReminder(todo.id);

    print('[WebNotif] Dijadwalkan "${todo.title}" dalam ${delay.inSeconds}s');

    _timers[todo.id] = Timer(delay, () {
      _trigger(todo);
    });
  }

  // ── Trigger popup sekarang (emit ke stream) ────────────────────────────────
  static void _trigger(Todo todo) {
    print('[WebNotif] ⏰ Waktunya! "${todo.title}"');

    if (!_controller.isClosed) {
      _controller.add(WebNotificationEvent(
        todoId: todo.id,
        title: todo.title,
        description: todo.description,
        scheduledAt: todo.reminderAt,
      ));
    }

    _timers.remove(todo.id);
  }

  // ── Batalkan reminder satu todo ────────────────────────────────────────────
  static void cancelTodoReminder(int todoId) {
    if (_timers.containsKey(todoId)) {
      _timers[todoId]!.cancel();
      _timers.remove(todoId);
      print('[WebNotif] Dibatalkan timer untuk todo $todoId');
    }
  }

  // ── Batalkan semua reminder ────────────────────────────────────────────────
  static void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    print('[WebNotif] Semua timer dibatalkan');
  }

  // ── Info jumlah timer aktif ────────────────────────────────────────────────
  static int get activeCount => _timers.length;

  // ── Dispose stream (panggil saat app ditutup) ──────────────────────────────
  static void dispose() {
    cancelAll();
    _controller.close();
  }
}
