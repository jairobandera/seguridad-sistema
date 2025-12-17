import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/storage/session_manager.dart';
import 'contactos_page.dart';

import '../../auth/pages/login_page.dart';
import 'historial_eventos_page.dart';
import 'wifi_page.dart';

class DashboardCliente extends StatefulWidget {
  const DashboardCliente({super.key});

  @override
  State<DashboardCliente> createState() => _DashboardClienteState();
}

class _DashboardClienteState extends State<DashboardCliente> {
  bool loading = true;

  Map<String, dynamic>? meData;

  bool seguridadActiva = false;

  // ESTADOS (se van a alimentar con /me + /evento/ultimos)
  bool puertaAbierta = false;
  bool dispositivoOnline = true;

  // Últimos eventos (para la card y para el historial)
  List<Map<String, dynamic>> _ultimosEventos = [];
  Map<String, dynamic>? _ultimoEvento;
  bool _cargandoEventos = false;

  final ApiClient api = ApiClient();
  late final AuthService auth = AuthService(api);

  @override
  void initState() {
    super.initState();
    _loadMe();

    // 🔁 refresco automático cada 15 segundos
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _refreshAll();
    });
  }

  // =======================================
  // Cargar /me
  // =======================================
  Future<void> _loadMe() async {
    try {
      final storedToken = await SessionManager.getToken();
      if (storedToken == null) {
        _goToLogin();
        return;
      }

      api.token = storedToken;

      final data = await auth.getMe();

      // --- ESTADO ONLINE DEL DISPOSITIVO ---
      bool online = true;
      bool alarma = false;

      if (data["casas"] is List && data["casas"].isNotEmpty) {
        final casa0 = data["casas"][0] as Map<String, dynamic>;
        alarma = casa0["alarmaArmada"] == true;

        if (casa0["dispositivos"] is List && casa0["dispositivos"].isNotEmpty) {
          final disp0 = casa0["dispositivos"][0] as Map<String, dynamic>;
          online = disp0["online"] == true;
        }
      }

      setState(() {
        meData = data;
        dispositivoOnline = online;
        seguridadActiva = alarma; // ← AHORA REAL DEL BACKEND
        loading = false;
      });

      // Cargar eventos
      await _loadUltimosEventos();
    } catch (e) {
      print("ERROR cargando /me → $e");
      _goToLogin();
    }
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

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // =======================================
  // Cargar /api/eventos/ultimos
  // =======================================
  Future<void> _loadUltimosEventos() async {
    if (!mounted) return;

    try {
      setState(() {
        _cargandoEventos = true;
      });

      final resp = await api.get("/api/eventos/ultimos?limit=10");

      List<Map<String, dynamic>> lista = [];

      if (resp is List) {
        lista = resp
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (resp is Map && resp["eventos"] is List) {
        lista = (resp["eventos"] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      Map<String, dynamic>? ultimo;
      if (lista.isNotEmpty) {
        ultimo = lista.first;
      }

      // Estado de puerta
      bool puertaIsOpen = puertaAbierta;
      if (ultimo != null) {
        final tipo = (ultimo["tipo"] ?? "") as String;
        puertaIsOpen = tipo == "PUERTA_ABIERTA";
      }

      if (!mounted) return;
      setState(() {
        _ultimosEventos = lista;
        _ultimoEvento = ultimo;
        puertaAbierta = puertaIsOpen;
        _cargandoEventos = false;
      });
    } catch (e) {
      print("ERROR cargando eventos → $e");
      if (!mounted) return;
      setState(() {
        _cargandoEventos = false;
      });
    }
  }

  // =======================================
  // Cambiar seguridad en el backend
  // =======================================
  Future<void> _toggleSeguridad() async {
    if (meData == null) return;

    final casas = meData!["casas"];
    if (casas is! List || casas.isEmpty) return;

    final casaId = casas[0]["id"];
    final nuevoEstado = !seguridadActiva;

    try {
      await api.post(
        "/api/casa/$casaId/seguridad",
        data: {"alarmaArmada": nuevoEstado},
      );

      setState(() {
        seguridadActiva = nuevoEstado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado ? "🔒 Seguridad activada" : "🔓 Seguridad desactivada",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error cambiando seguridad: $e")),
      );
    }
  }

  // =======================================
// REFRESH AUTOMÁTICO DE ESTADOS
// =======================================
  Future<void> _refreshAll() async {
    try {
      final storedToken = await SessionManager.getToken();
      if (storedToken == null) return;

      api.token = storedToken;

      // ====================================
      // Obtener /me otra vez
      // ====================================
      final data = await auth.getMe();

      bool online = true;
      bool alarma = seguridadActiva;

      if (data["casas"] is List && data["casas"].isNotEmpty) {
        final casa0 = data["casas"][0];

        alarma = casa0["alarmaArmada"] == true;

        if (casa0["dispositivos"] is List && casa0["dispositivos"].isNotEmpty) {
          final disp0 = casa0["dispositivos"][0];
          online = disp0["online"] == true;
        }
      }

      // ====================================
      // Obtener últimos eventos otra vez
      // ====================================
      final resp = await api.get("/api/eventos/ultimos?limit=10");

      List<Map<String, dynamic>> lista = [];

      if (resp is List) {
        lista = resp
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (resp is Map && resp["eventos"] is List) {
        lista = (resp["eventos"] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      Map<String, dynamic>? ultimo;
      if (lista.isNotEmpty) ultimo = lista.first;

      bool puertaIsOpen = puertaAbierta;
      if (ultimo != null) {
        final tipo = (ultimo["tipo"] ?? "");
        puertaIsOpen = tipo == "PUERTA_ABIERTA";
      }

      if (!mounted) return;

      setState(() {
        dispositivoOnline = online;
        seguridadActiva = alarma;
        puertaAbierta = puertaIsOpen;
        _ultimoEvento = ultimo;
        _ultimosEventos = lista;
      });
    } catch (_) {
      // evitar spam de errores silenciosos
    }
  }

  // =======================================
  // Helpers
  // =======================================
  String _textoEvento(Map<String, dynamic> ev) {
    final tipo = (ev["tipo"] ?? "") as String;
    switch (tipo) {
      case "PUERTA_ABIERTA":
        return "Puerta abierta";
      case "PUERTA_CERRADA":
        return "Puerta cerrada";
      case "DISPOSITIVO_OFFLINE":
        return "Dispositivo offline";
      default:
        return tipo.isNotEmpty ? tipo : "Evento";
    }
  }

  String _horaEvento(Map<String, dynamic> ev) {
    final fechaStr = ev["fechaHora"] as String?;
    if (fechaStr == null) return "";
    try {
      final dt = DateTime.parse(fechaStr).toLocal();
      final hh = dt.hour.toString().padLeft(2, "0");
      final mm = dt.minute.toString().padLeft(2, "0");
      return "$hh:$mm";
    } catch (_) {
      return "";
    }
  }

  void _abrirHistorialEventos() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistorialEventosPage(api: api)),
    );
  }

  // =======================================
  // UI
  // =======================================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0F),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final nombre = meData?['nombre'] ?? 'Usuario';
    final email = meData?['email'] ?? 'correo no disponible';
    final rol = meData?['rol'] ?? 'CLIENTE';

    // Nombre de casa
    String casaNombre = "Casa asignada";
    final casas = meData?["casas"];
    if (casas is List && casas.isNotEmpty) {
      final c = casas[0] as Map<String, dynamic>;
      final calle = (c["calle"] ?? "") as String;
      final numero = (c["numero"] ?? "") as String;
      casaNombre = (calle.isNotEmpty || numero.isNotEmpty)
          ? "$calle $numero"
          : casaNombre;
    }

    String ultimoTexto = "Sin eventos recientes";
    String ultHora = "";
    if (_ultimoEvento != null) {
      ultimoTexto = _textoEvento(_ultimoEvento!);
      ultHora = _horaEvento(_ultimoEvento!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: const Text(
          "Panel del Cliente",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CASA
            _card(
              child: Row(
                children: [
                  const Icon(Icons.home_outlined,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      casaNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ESTADOS
            Row(
              children: [
                Expanded(
                  child: _estadoCard(
                    title: dispositivoOnline ? "ONLINE" : "OFFLINE",
                    icon: dispositivoOnline ? Icons.check_circle : Icons.cancel,
                    color: dispositivoOnline
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _estadoCard(
                    title: puertaAbierta ? "PUERTA ABIERTA" : "PUERTA CERRADA",
                    icon: puertaAbierta
                        ? Icons.door_front_door
                        : Icons.meeting_room_outlined,
                    color: puertaAbierta
                        ? Colors.redAccent
                        : Colors.blueAccent.shade100,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ULTIMO EVENTO
            GestureDetector(
              onTap: _ultimosEventos.isEmpty ? null : _abrirHistorialEventos,
              child: _card(
                child: Row(
                  children: [
                    Icon(Icons.history,
                        color: Colors.blueAccent.shade100, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _cargandoEventos
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Último evento",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ultHora.isNotEmpty
                                      ? "$ultimoTexto — $ultHora"
                                      : ultimoTexto,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                )
                              ],
                            ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // ACTIVAR / DESACTIVAR SEGURIDAD
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleSeguridad,
                style: ElevatedButton.styleFrom(
                  backgroundColor: seguridadActiva
                      ? Colors.redAccent
                      : Colors.greenAccent.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  seguridadActiva
                      ? "Desactivar seguridad"
                      : "Activar seguridad",
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // OPCIONES
            Row(
              children: [
                Expanded(
                  child: _opcionBoton(
                    icon: Icons.contacts_outlined,
                    label: "Contactos",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContactosPage(api: api),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _opcionBoton(
                    icon: Icons.list_alt_outlined,
                    label: "Historial",
                    onTap: _abrirHistorialEventos,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _opcionBoton(
                    icon: Icons.wifi,
                    label: "WiFi",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WifiPage(
                            casaNombre: casaNombre,
                            dispositivoOnline: dispositivoOnline,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                    child: SizedBox()), // para mantener el layout 2 columnas
              ],
            ),

            const SizedBox(height: 50),

            // USER INFO
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info("Nombre", nombre),
                  _info("Email", email),
                  //_info("Rol", rol),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // COMPONENTES UI ==========================

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _estadoCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  Widget _opcionBoton({
    required IconData icon,
    required String label,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent.shade100),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            )
          ],
        ),
      ),
    );
  }
}
