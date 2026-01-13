import 'package:flutter/material.dart';
import '../storage/session_manager.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final token = SessionManager.getToken();

    if (token == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    // Si el token expiró, limpiamos y mandamos a login
    // (opcional, pero recomendado)
    // Si no usás expiración en JWT, podés borrar este bloque.
    try {
      final role = SessionManager.getRoleFromToken(token);

      if (!mounted) return;

      if (role == "CLIENTE") {
        Navigator.pushReplacementNamed(context, "/cliente");
      } else if (role == "GUARDIA") {
        Navigator.pushReplacementNamed(context, "/guardia");
      } else if (role == "ADMIN") {
        Navigator.pushReplacementNamed(context, "/admin");
      } else {
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (_) {
      await SessionManager.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0E0E0F),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
