// lib/services/auth_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyName  = 'user_name';
  static const _keyEmail = 'user_email';
  static const _keyId    = 'user_id';

  // ── Register ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return ApiService.post(ApiConfig.register, {
      'name':     name,
      'email':    email,
      'password': password,
    });
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiService.post(ApiConfig.login, {
      'email':    email,
      'password': password,
    });

    if (res['status'] == 'success') {
      final data = res['data'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, data['token']);
      await prefs.setInt   (_keyId,    data['user']['id']);
      await prefs.setString(_keyName,  data['user']['name']);
      await prefs.setString(_keyEmail, data['user']['email']);
    }

    return res;
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await ApiService.postAuth(ApiConfig.logout, {}, token);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Helpers sesi ─────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<bool> isLoggedIn() async => (await getToken()) != null;

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id    = prefs.getInt(_keyId);
    final name  = prefs.getString(_keyName);
    final email = prefs.getString(_keyEmail);
    if (id == null || name == null || email == null) return null;
    return User(id: id, name: name, email: email);
  }
}
