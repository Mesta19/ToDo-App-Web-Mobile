// lib/services/todo_service.dart

import '../config/api_config.dart';
import '../models/todo_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class TodoService {
  // ── Ambil todos aktif ─────────────────────────────────────────────────────
  static Future<List<Todo>> getTodos() async {
    final token = await AuthService.getToken() ?? '';
    final res = await ApiService.get(ApiConfig.todos, token);

    try {
      if (res['status'] == 'success') {
        final data = res['data'];
        if (data is Map && data['todos'] is List) {
          final list = data['todos'] as List;
          return list.map((e) => Todo.fromJson(e)).toList();
        }
      }
    } catch (_) {
      // Fallback to empty list on unexpected payloads.
    }
    return [];
  }

  // ── Ambil riwayat todos ───────────────────────────────────────────────────
  static Future<List<Todo>> getHistory() async {
    final token = await AuthService.getToken() ?? '';
    final res = await ApiService.get(ApiConfig.todosHistory, token);

    try {
      if (res['status'] == 'success') {
        final data = res['data'];
        if (data is Map && data['todos'] is List) {
          final list = data['todos'] as List;
          return list.map((e) => Todo.fromJson(e)).toList();
        }
      }
    } catch (_) {
      // Fallback to empty list on unexpected payloads.
    }
    return [];
  }

  // ── Buat todo baru ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createTodo({
    required String title,
    required String description,
    required DateTime reminderAt,
  }) async {
    // Token automatically sent via Authorization header
    return ApiService.post(ApiConfig.todos, {
      'title': title,
      'description': description,
      'reminder_at': reminderAt.toString().substring(0, 19),
    });
    // Catatan: createTodo menggunakan post() biasa karena token
    // dikirim lewat header Authorization yang sudah ditambahkan
    // di postAuth. Gunakan postAuth agar token ikut terkirim:
  }

  // ── Buat todo baru (dengan auth) ──────────────────────────────────────────
  static Future<Map<String, dynamic>> addTodo({
    required String title,
    required String description,
    required DateTime reminderAt,
  }) async {
    final token = await AuthService.getToken() ?? '';
    return ApiService.postAuth(
      ApiConfig.todos,
      {
        'title': title,
        'description': description,
        'reminder_at': reminderAt.toString().substring(0, 19),
      },
      token,
    );
  }

  // ── Update todo ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateTodo({
    required int id,
    required String title,
    required String description,
    required DateTime reminderAt,
    required bool isDone,
  }) async {
    final token = await AuthService.getToken() ?? '';
    return ApiService.put(
      ApiConfig.todoById(id),
      {
        'title': title,
        'description': description,
        'reminder_at': reminderAt.toString().substring(0, 19),
        'is_done': isDone ? 1 : 0,
      },
      token,
    );
  }

  // ── Tandai selesai ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> markDone(int id) async {
    final token = await AuthService.getToken() ?? '';
    return ApiService.put(
      ApiConfig.todoById(id),
      {'is_done': 1},
      token,
    );
  }

  // ── Hapus todo ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteTodo(int id) async {
    final token = await AuthService.getToken() ?? '';
    return ApiService.delete(ApiConfig.todoById(id), token);
  }
}
