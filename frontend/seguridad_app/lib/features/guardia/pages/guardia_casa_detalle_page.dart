import 'package:flutter/material.dart';
import '../models/guardia_api.dart';
import '../models/casa_guardia.dart';
import '../models/evento_guardia.dart';

class GuardiaCasaDetallePage extends StatefulWidget {
  final GuardiaApi api;
  final CasaGuardia casa;

  const GuardiaCasaDetallePage({super.key, required this.api, required this.casa});

  @override
  State<GuardiaCasaDetallePage> createState() => _GuardiaCasaDetallePageState();
}

class _GuardiaCasaDetallePageState extends State<GuardiaCasaDetallePage> {
  bool loading = true;
  List<EventoGuardia> eventos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    eventos = await widget.api.listarEventos(casaId: widget.casa.id);
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.casa;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: const Text("Detalle", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoCard(c),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Eventos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (loading)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (eventos.isEmpty)
                    const Text("Sin eventos", style: TextStyle(color: Colors.white54))
                  else
                    ...eventos.take(5).map(_tileEvento),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(CasaGuardia c) {
    final dir = "${c.calle} ${c.numero}".trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.cliente, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text([dir, c.barrio].where((x) => x.trim().isNotEmpty).join(" · "), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(c.dispositivoOnline ? "ONLINE" : "OFFLINE", c.dispositivoOnline ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 8),
              _chip(c.alarmaArmada ? "ARMADA" : "DESARMADA", c.alarmaArmada ? Colors.orangeAccent : Colors.white70),
            ],
          )
        ],
      ),
    );
  }

  Widget _tileEvento(EventoGuardia e) {
    final hh = e.fecha.hour.toString().padLeft(2, '0');
    final mm = e.fecha.minute.toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(e.tipo == "DISPOSITIVO_OFFLINE" ? Icons.wifi_off : Icons.event, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.tipo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          Text("$hh:$mm", style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
