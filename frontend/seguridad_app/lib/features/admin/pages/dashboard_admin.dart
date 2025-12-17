import 'package:flutter/material.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Admin")),
      body: const Center(
        child: Text(
          "Dashboard Admin (placeholder)",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
