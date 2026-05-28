// lib/services/api_service.dart
// HTTP helper — semua URL diambil dari ApiConfig, tidak ada string URL di sini.

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Header JSON biasa
  static Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
      };

  // Header JSON + Bearer token
  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
      };

  // ── POST tanpa auth (register / login) ──────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _jsonHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // ── POST dengan auth ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> postAuth(
    String url,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // ── GET dengan auth ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String url, String token) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // ── PUT dengan auth ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // ── DELETE dengan auth ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String url, String token) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _authHeaders(token))
          .timeout(const Duration(seconds: 15));
      return _parse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // ── Parse response ───────────────────────────────────────────────────────
  static Map<String, dynamic> _parse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'message': 'Respons server tidak valid.'};
    }
  }
}
