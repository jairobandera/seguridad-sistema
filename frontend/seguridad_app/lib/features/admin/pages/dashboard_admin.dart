import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/session_manager.dart';
import '../../auth/pages/login_page.dart';

import '../services/admin_api.dart';
import 'usuarios/admin_usuarios_page.dart';
import 'casas/admin_casas_page.dart';
import '../services/admin_casas_api.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final ApiClient api = ApiClient();
  late final AdminApi adminApi = AdminApi(api);

  int selectedIndex = 0; // 0 = usuarios, 1 = casas

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final token = SessionManager.getToken();
    if (token == null) {
      _goToLogin();
      return;
    }
    api.token = token;
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _logout() async {
    await SessionManager.clear();
    api.token = null;
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminUsuariosPage(api: adminApi),
      AdminCasasPage(
        api: AdminCasasApi(api),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: const Text(
          "Panel Administrador",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: Row(
        children: [
          _sidebar(),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ✅ Usuarios
          _sideItem(
            icon: Icons.people_alt_rounded,
            title: "Usuarios",
            selected: selectedIndex == 0,
            onTap: () => setState(() => selectedIndex = 0),
          ),

          // ✅ Casas
          _sideItem(
            icon: Icons.home_rounded,
            title: "Casas",
            selected: selectedIndex == 1,
            onTap: () => setState(() => selectedIndex = 1),
          ),

          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Admin Web v1.0",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.blueAccent.shade100 : Colors.white70,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: selected ? Colors.white : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
