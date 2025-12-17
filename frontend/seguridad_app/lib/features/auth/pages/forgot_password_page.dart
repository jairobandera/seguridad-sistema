import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar contraseña")),
      body: const Center(
        child: Text(
          "Pantalla de recuperación (placeholder)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
