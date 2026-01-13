import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionManager {
  static late SharedPreferences _prefs;
  static String? _ephemeralToken;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Si querés: recuperar token a memoria (no es obligatorio)
    _ephemeralToken = null;
  }

  static String? getRoleFromToken(String token) {
    try {
      final decoded = JwtDecoder.decode(token);
      return decoded["rol"];
    } catch (e) {
      return null;
    }
  }

  static void saveSession(String token, String rol) {
    _prefs.setString("token", token);
    _prefs.setString("rol", rol);
  }

  // ✅ Persistente (recordarme)
  static Future<void> saveToken(String token) async {
    await _prefs.setString("token", token);
  }

  // ✅ Token: primero memoria (si existe), si no prefs
  static String? getToken() => _ephemeralToken ?? _prefs.getString("token");

  static String? getRole() => _prefs.getString("rol");

  static Future<void> clear() async {
    _ephemeralToken = null;
    await _prefs.clear();
  }

  // ✅ Solo sesión actual (no recordarme)
  static Future<void> saveTokenEphemeral(String token) async {
    _ephemeralToken = token;
  }

  static Future<void> clearEphemeral() async {
    _ephemeralToken = null;
  }
}
