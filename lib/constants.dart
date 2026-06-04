// lib/constants.dart

class AppConstants {
  // Ganti IP sesuai komputer Anda saat test di device fisik.
  // Gunakan 10.0.2.2 untuk emulator Android, atau IP LAN untuk device nyata.
  static const String baseUrl = 'http://10.0.2.2/todo_api/api';

  // SharedPreferences keys
  static const String keyToken = 'auth_token';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserId = 'user_id';
}
