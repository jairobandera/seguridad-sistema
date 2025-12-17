// lib/core/auth/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_client.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  static const _tokenKey = 'auth_token';

  // ===========================
  // LOGIN
  // ===========================
  Future<String> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final body = {
      "email": email,
      "password": password,
    };

    final resp = await _api.post('/api/auth/login', data: body);

    if (resp is! Map) {
      throw ApiException('Respuesta inesperada del servidor');
    }

    final ok = resp['ok'];
    if (!(ok == true || ok == "true" || ok == 1)) {
      throw ApiException("Credenciales inválidas");
    }

    final token = resp['token'];
    if (token == null) {
      throw ApiException("El servidor no devolvió token");
    }

    // Guardar token localmente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    // Importante: guardarlo en ApiClient para que se use AUTOMÁTICAMENTE
    _api.token = token;

    return token;
  }

  // ===========================
  // GET TOKEN GUARDADO
  // ===========================
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ===========================
  // LOGOUT
  // ===========================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _api.token = null;
  }

  // ===========================
  // /me
  // ===========================
  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.get('/api/me');
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw ApiException("Respuesta inesperada al obtener /me");
  }
}
