import 'package:flutter/material.dart';

import '../models/guardia_api.dart';
import '../models/casa_guardia.dart';
import 'guardia_notificaciones_casa_page.dart';
import 'dart:async';
import '../../../core/realtime/guardia_socket.dart';

class GuardiaNotificacionesPage extends StatefulWidget {
  final GuardiaApi api;
  const GuardiaNotificacionesPage({super.key, required this.api});

  @override
  State<GuardiaNotificacionesPage> createState() =>
      _GuardiaNotificacionesPageState();
}

class _GuardiaNotificacionesPageState extends State<GuardiaNotificacionesPage> {
  bool loading = true;
  List<CasaGuardia> casasConNotif = [];
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

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _load(); // recarga contadores y casas
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    final casas = await widget.api.listarCasas();

    // ✅ solo las casas que tienen notificaciones (ya filtradas en backend a PUERTA_*)
    casasConNotif = casas.where((c) => c.eventosNoLeidos > 0).toList();

    // orden: más notifs arriba
    casasConNotif
        .sort((a, b) => b.eventosNoLeidos.compareTo(a.eventosNoLeidos));

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _changed),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title:
            const Text("Notificaciones", style: TextStyle(color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (casasConNotif.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        "No hay notificaciones de puertas.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ...casasConNotif.map(_cardCasa),
                ],
              ),
            ),
    );
  }

  Widget _cardCasa(CasaGuardia c) {
    final dir = "${c.calle} ${c.numero}".trim();
    final sub = [dir, c.barrio].where((x) => x.trim().isNotEmpty).join(" · ");

    return InkWell(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GuardiaNotificacionesCasaPage(api: widget.api, casa: c),
          ),
        );

        if (changed == true) {
          _changed = true;
          await _load();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.home_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.cliente,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(sub, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _pill("${c.eventosNoLeidos}", Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
