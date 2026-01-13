// lib/features/auth/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/storage/session_manager.dart';

//import '../../cliente/pages/dashboard_cliente.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool loading = false;
  bool rememberMe = true;
  bool showPass = false;
  String? errorText;

  final ApiClient api = ApiClient(); // 🔥 IMPORTANTE: singleton
  late final AuthService auth = AuthService(api);

  // ============================
  // LOGIN
  // ============================
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // Login usando SIEMPRE el mismo ApiClient
      final token = await auth.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      //Recordarme: persistente vs solo en memoria
      if (rememberMe) {
        await SessionManager.saveToken(token);
      } else {
        await SessionManager.saveTokenEphemeral(token);
      }

      // 🔥 Guardamos el token en SessionManager
      await SessionManager.saveToken(token);

      // 🔥 Ajustamos api.token para el resto de la app
      api.token = token;

      print("TOKEN CORRECTO: $token");

      // ================================
      // OBTENER TOKEN FCM DEL DISPOSITIVO
      // ================================
      try {
        // ====================================
        // PEDIR PERMISO DE NOTIFICACIONES
        // ====================================
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: true,
        );

        print("🔔 Permiso notificaciones: ${settings.authorizationStatus}");

        final fcm = FirebaseMessaging.instance;
        final fcmToken = await fcm.getToken();

        print("🔥 TOKEN FCM DISPOSITIVO → $fcmToken");

        if (fcmToken != null) {
          await api.post(
            "/api/usuarios/fcm-token",
            data: {"token": fcmToken},
          );
        }
      } catch (e) {
        print("ERROR registrando FCM TOKEN → $e");
      }

      // Extraer rol del token o SessionManager
      final role = SessionManager.getRoleFromToken(token);

      if (!mounted) return;

      // Navegación según Rol
      if (role == "CLIENTE") {
        Navigator.pushReplacementNamed(context, "/cliente");
      } else if (role == "GUARDIA") {
        Navigator.pushReplacementNamed(context, "/guardia");
      } else if (role == "ADMIN") {
        Navigator.pushReplacementNamed(context, "/admin");
      } else {
        setState(() => errorText = "Rol desconocido");
      }
    } catch (e) {
      print("ERROR LOGIN: $e");
      setState(() => errorText = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0F),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LOGO
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 90,
                            color: Colors.blueAccent.shade100,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Seguridad Hogar",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (errorText != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),

                    if (errorText != null) const SizedBox(height: 18),

                    // EMAIL
                    _inputDark(
                      controller: _emailCtrl,
                      label: "Email",
                      icon: Icons.email_outlined,
                      validator: (v) => v!.isEmpty ? "Ingrese un email" : null,
                    ),

                    const SizedBox(height: 18),

                    // PASS
                    _passwordDark(),

                    const SizedBox(height: 35),

                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (v) =>
                              setState(() => rememberMe = v ?? true),
                          activeColor: Colors.blueAccent,
                          checkColor: Colors.white,
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.35)),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Recordarme",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: loading ? null : login,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Ingresar",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, "/forgot"),
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            color: Colors.blueAccent.shade100,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================
  // INPUT
  // ============================
  Widget _inputDark({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.blueAccent.shade100),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.4),
        ),
      ),
    );
  }

  // ============================
  // PASSWORD
  // ============================
  Widget _passwordDark() {
    return TextFormField(
      controller: _passCtrl,
      validator: (v) => v!.isEmpty ? "Ingrese su contraseña" : null,
      obscureText: !showPass,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent.shade100),
        suffixIcon: IconButton(
          onPressed: () => setState(() => showPass = !showPass),
          icon: Icon(
            showPass ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.4),
        ),
      ),
    );
  }
}
