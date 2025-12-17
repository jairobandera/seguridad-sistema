import 'package:flutter/material.dart';

class DashboardGuardia extends StatelessWidget {
  const DashboardGuardia({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Guardia")),
      body: const Center(
        child: Text(
          "Dashboard Guardia (placeholder)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
