import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/session_manager.dart';
import '../../auth/pages/login_page.dart';

import '../models/guardia_api.dart';
import '../pages/guardia_notificaciones_page.dart';
import '../pages/guardia_casas_page.dart';
import 'dart:async';
import '../../../core/realtime/guardia_socket.dart';

class DashboardGuardia extends StatefulWidget {
  const DashboardGuardia({super.key});

  @override
  State<DashboardGuardia> createState() => _DashboardGuardiaState();
}

class _DashboardGuardiaState extends State<DashboardGuardia> {
  final ApiClient api = ApiClient();
  late final GuardiaApi guardiaApi = GuardiaApi(api);

  bool loading = true;

  int notifCount = 0;
  int casasCount = 0;

  String nombre = "Guardia";
  String email = "";

  StreamSubscription? _sub;
  Timer? _debounce;

  final List<Map<String, dynamic>> _alertQueue = [];
  bool _showingAlert = false;

  @override
  void initState() {
    super.initState();
    _load();
    _initRealtime();
  }

  Future<void> _initRealtime() async {
    final token = await SessionManager.getToken();
    if (token == null) return;

    await GuardiaSocket().connect(token);

    _sub?.cancel();
    _sub = GuardiaSocket().events.listen((event) {
      print('SOCKET EVENT: $event');
      final tipo = (event['tipo'] ?? '').toString();

      if (tipo == 'PUERTA_ABIERTA') {
        // 🔢 subir contador instantáneo (sin esperar refresh)
        setState(() {
          notifCount = notifCount + 1;
        });

        _enqueueAlerta(event);

        // (opcional pero recomendado) reconciliación con backend por seguridad
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 600), () {
          if (mounted) _load();
        });
      }

      if (tipo == 'EVENTO_ESTADO_ACTUALIZADO') {
        final bool atendido = event['atendido'] == true;
        final bool leido = event['leido'] == true;

        // 🔢 ACTUALIZACIÓN INMEDIATA DEL CONTADOR
        if (atendido || leido) {
          if (notifCount > 0) {
            setState(() {
              notifCount = notifCount - 1;
            });
          }
        }

        // 🔄 Reconciliación con backend (seguridad)
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) _load();
        });
      }
    });
  }

  void _enqueueAlerta(Map<String, dynamic> ev) {
    _alertQueue.add(ev);
    _tryShowNextAlert();
  }

  void _tryShowNextAlert() {
    if (_showingAlert || _alertQueue.isEmpty || !mounted) return;

    _showingAlert = true;
    final ev = _alertQueue.removeAt(0);
    _mostrarAlertaPuerta(ev);
  }

  void _mostrarAlertaPuerta(Map<String, dynamic> ev) {
    final casa = ev['casa'];
    final cliente = ev['cliente'];

    String casaTxt = '';
    if (casa is Map) {
      casaTxt = [
        casa['calle'],
        casa['numero'] ?? casa['codigo'],
        casa['barrio'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(' ');
    }

    String cliTxt = '';
    if (cliente is Map) {
      cliTxt = '${cliente['nombre'] ?? ''} ${cliente['apellido'] ?? ''}'.trim();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'alerta',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F24),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'PUERTA ABIERTA',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                if (cliTxt.isNotEmpty)
                  Text(cliTxt,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                if (casaTxt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      casaTxt,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showingAlert = false;
                    _tryShowNextAlert();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'CONFIRMAR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() => loading = true);

    final token = await SessionManager.getToken();
    if (token == null) return _goToLogin();

    api.token = token;

    try {
      final panel = await guardiaApi.cargarPanel();
      final casas = await guardiaApi.listarCasas();

      // /api/me para datos guardia
      final me = await api.get('/api/me');
      if (me is Map) {
        nombre = (me['nombre'] ?? "Guardia").toString();
        email = (me['email'] ?? "").toString();
      }

      notifCount = casas.fold<int>(0, (sum, c) => sum + c.eventosNoLeidos);
      casasCount = casas.length;
    } catch (_) {
      return _goToLogin();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _logout() async {
    GuardiaSocket().disconnect();
    await SessionManager.clear();
    api.token = null;
    _goToLogin();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: const Text("Panel del Guardia",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _bigCard(
              title: "Notificaciones",
              count: notifCount,
              icon: Icons.notifications_active,
              onTap: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuardiaNotificacionesPage(api: guardiaApi),
                  ),
                );

                if (changed == true) {
                  await _load();
                }
              },
            ),
            const SizedBox(height: 12),
            _bigCard(
              title: "Casas",
              count: casasCount,
              icon: Icons.home_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GuardiaCasasPage(api: guardiaApi)),
              ),
            ),
            const SizedBox(height: 18),
            _infoCard(nombre: nombre, email: email),
          ],
        ),
      ),
    );
  }

  Widget _bigCard({
    required String title,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    // 🎨 Color por sección
    final Color accent = title.toLowerCase().contains('notifi')
        ? Colors.blueAccent
        : Colors.greenAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: accent.withOpacity(0.28)), // ✅ borde con acento
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.10),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ Icono con fondo “badge”
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withOpacity(0.22)),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // ✅ Contador con acento
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withOpacity(0.22)),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String nombre, required String email}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Datos", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(nombre,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          if (email.isNotEmpty)
            Text(email, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
