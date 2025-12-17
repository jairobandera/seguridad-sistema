import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class HistorialEventosPage extends StatefulWidget {
  final ApiClient api;

  const HistorialEventosPage({super.key, required this.api});

  @override
  State<HistorialEventosPage> createState() => _HistorialEventosPageState();
}

class _HistorialEventosPageState extends State<HistorialEventosPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _eventos = [];

  @override
  void initState() {
    super.initState();
    _loadEventos();
  }

  Future<void> _loadEventos() async {
    try {
      final resp = await widget.api.get("/api/eventos/ultimos?limit=10");

      List<Map<String, dynamic>> lista = [];
      if (resp is List) {
        lista =
            resp.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
                .toList();
      } else if (resp is Map && resp["eventos"] is List) {
        lista = (resp["eventos"] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _eventos = lista;
        _loading = false;
      });
    } catch (e) {
      print("ERROR cargando historial de eventos → $e");
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

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

  String _fechaHoraEvento(Map<String, dynamic> ev) {
    final fechaStr = ev["fechaHora"] as String?;
    if (fechaStr == null) return "";
    try {
      final dt = DateTime.parse(fechaStr).toLocal();
      final hh = dt.hour.toString().padLeft(2, "0");
      final mm = dt.minute.toString().padLeft(2, "0");
      final dd = dt.day.toString().padLeft(2, "0");
      final mo = dt.month.toString().padLeft(2, "0");
      return "$dd/$mo $hh:$mm";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        title: const Text(
          "Historial de eventos",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _eventos.isEmpty
              ? const Center(
                  child: Text(
                    "No hay eventos recientes.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _eventos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ev = _eventos[index];
                    final titulo = _textoEvento(ev);
                    final fechaHora = _fechaHoraEvento(ev);
                    final origen = (ev["origen"] ?? "") as String;

                    IconData icon;
                    Color color;

                    switch (ev["tipo"]) {
                      case "PUERTA_ABIERTA":
                        icon = Icons.door_front_door;
                        color = Colors.redAccent;
                        break;
                      case "PUERTA_CERRADA":
                        icon = Icons.meeting_room_outlined;
                        color = Colors.blueAccent;
                        break;
                      case "DISPOSITIVO_OFFLINE":
                        icon = Icons.wifi_off;
                        color = Colors.orangeAccent;
                        break;
                      default:
                        icon = Icons.info_outline;
                        color = Colors.white70;
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fechaHora,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                if (origen.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Origen: $origen",
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
