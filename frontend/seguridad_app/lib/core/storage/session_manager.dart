import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SessionManager {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }


  static String? getToken() => _prefs.getString("token");
  static String? getRole() => _prefs.getString("rol");

  static Future<void> clear() async {
    await _prefs.clear();
  }
}
