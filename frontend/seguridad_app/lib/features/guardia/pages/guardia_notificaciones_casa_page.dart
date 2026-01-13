import 'package:flutter/material.dart';

import '../models/guardia_api.dart';
import '../models/casa_guardia.dart';
import '../models/evento_guardia.dart';
import 'dart:async';
import '../../../core/realtime/guardia_socket.dart';

class GuardiaNotificacionesCasaPage extends StatefulWidget {
  final GuardiaApi api;
  final CasaGuardia casa;

  const GuardiaNotificacionesCasaPage({
    super.key,
    required this.api,
    required this.casa,
  });

  @override
  State<GuardiaNotificacionesCasaPage> createState() =>
      _GuardiaNotificacionesCasaPageState();
}

class _GuardiaNotificacionesCasaPageState
    extends State<GuardiaNotificacionesCasaPage> {
  bool loading = true;
  List<EventoGuardia> eventos = [];
  StreamSubscription? _sub;
  Timer? _debounce;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();

    _sub = GuardiaSocket().events.listen((ev) {
      final tipo = (ev['tipo'] ?? '').toString();
      if (tipo != 'PUERTA_ABIERTA' && tipo != 'PUERTA_CERRADA') return;

      // opcional: si el payload trae casa.id, filtrá por casa actual
      final casa = ev['casa'];
      final casaId = (casa is Map) ? casa['id'] : null;
      if (casaId != null && casaId != widget.casa.id) return;

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _load(); // recarga lista de eventos
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  bool _esPuerta(String tipo) =>
      tipo == "PUERTA_ABIERTA" || tipo == "PUERTA_CERRADA";

  Future<void> _load() async {
    setState(() => loading = true);

    final all = await widget.api.listarEventos(casaId: widget.casa.id);

    // SOLO PUERTA + SOLO NO ATENDIDOS (si querés ocultar completados)
    eventos = all.where((e) => _esPuerta(e.tipo) && !e.atendido).toList();

    // solo últimos 5
    eventos = eventos.take(5).toList();

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _marcarLeido(int id) async {
    await widget.api.marcarLeido(id);
    _changed = true;
    await _load();
  }

  Future<void> _marcarAtendido(int id) async {
    await widget.api.marcarAtendido(id);
    await widget.api
        .marcarLeido(id); // ✅ para que baje el contador de no leídos
    _changed = true;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.casa;
    final dir = "${c.calle} ${c.numero}".trim();
    final sub = [dir, c.barrio].where((x) => x.trim().isNotEmpty).join(" · ");

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(
            context, _changed); // ✅ devuelve true/false al padre siempre
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0F),
        appBar: AppBar(
          // ✅ back controlado (flecha de arriba)
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _changed),
          ),

          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF0E0E0F),
          elevation: 0,
          title: Text(
            c.cliente,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text(
                    "Marcar todo",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await widget.api.marcarTodoCasa(widget.casa.id);
                    _changed = true; // ✅ importante
                    await _load();
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Marcado todo como leído y atendido ✅"),
                      ),
                    );

                    // ✅ no te saca de la pantalla
                  },
                  icon: const Icon(Icons.done_all, color: Colors.greenAccent),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  sub.isEmpty ? "Casa" : sub,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (eventos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    "Sin eventos de puerta.",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...eventos.map(_tile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(EventoGuardia e) {
    final hh = e.fecha.hour.toString().padLeft(2, '0');
    final mm = e.fecha.minute.toString().padLeft(2, '0');

    final isOpen = e.tipo == "PUERTA_ABIERTA";
    final icon = isOpen ? Icons.door_front_door : Icons.meeting_room_outlined;
    final iconColor = isOpen ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              e.tipo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Text("$hh:$mm", style: const TextStyle(color: Colors.white54)),
          const SizedBox(width: 10),

          // ✅ Mini header + íconos (sin tooltips)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Leído / Atendido",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!e.leido)
                    IconButton(
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      onPressed: () => _marcarLeido(e.id),
                      icon: const Icon(
                        Icons.mark_email_read,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                    ),
                  if (!e.atendido)
                    IconButton(
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      onPressed: () => _marcarAtendido(e.id),
                      icon: const Icon(
                        Icons.task_alt,
                        color: Colors.greenAccent,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
