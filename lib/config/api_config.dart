// lib/config/api_config.dart
// ─────────────────────────────────────────────────────────────
// SATU-SATUNYA file yang berisi URL & endpoint.
// Jika ganti server, cukup ubah [baseUrl] di sini saja.
// ─────────────────────────────────────────────────────────────

class ApiConfig {
  // Ganti dengan IP komputer Anda jika test dari HP fisik.
  // Contoh: 'http://192.168.1.10/todo_api/api'
  // Untuk emulator Android gunakan: 'http://10.0.2.2/todo_api/api'
  // Ubah kembali menjadi localhost:
  /// Untuk emulator Android gunakan: 'http://10.0.2.2/todo_api/api'
// Ubah kembali menjadi localhost:
// static const String baseUrl = "http://localhost/todo_api/api";

// NOTE: sedang menggunakan ngrok public tunnel
  static const String baseUrl =
      "https://unfrazzled-lilyanna-nonsubordinating.ngrok-free.dev/todo_api/api";
  // ── Auth ──────────────────────────────────────────────────
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';

  // ── Todos ─────────────────────────────────────────────────
  static const String todos = '$baseUrl/todos';
  static const String todosHistory = '$baseUrl/todos/history';

  // Endpoint dengan ID dinamis → panggil sebagai fungsi
  static String todoById(int id) => '$baseUrl/todos/$id';
}
