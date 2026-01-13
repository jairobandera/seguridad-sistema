import 'package:flutter/material.dart';
import '../models/guardia_api.dart';
import '../models/casa_guardia.dart';
import 'guardia_casa_detalle_page.dart';
import 'dart:async';
import '../../../core/realtime/guardia_socket.dart';

class GuardiaCasasPage extends StatefulWidget {
  final GuardiaApi api;
  const GuardiaCasasPage({super.key, required this.api});

  @override
  State<GuardiaCasasPage> createState() => _GuardiaCasasPageState();
}

class _GuardiaCasasPageState extends State<GuardiaCasasPage> {
  bool loading = true;
  List<CasaGuardia> all = [];
  List<CasaGuardia> filtered = [];
  final ctrl = TextEditingController();
  bool showArmadas = true; // true = ARMADAS, false = DESARMADAS

  StreamSubscription? _sub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    ctrl.addListener(_apply);

    _sub = GuardiaSocket().events.listen((ev) {
      final tipo = (ev['tipo'] ?? '').toString();

      // solo puerta
      if (tipo != 'PUERTA_ABIERTA' && tipo != 'PUERTA_CERRADA') return;

      // debounce para evitar recargar 20 veces si llegan muchos
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () {
        if (mounted) _load();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    all = await widget.api.listarCasas();
    _apply();
    if (!mounted) return;
    setState(() => loading = false);
  }

  void _apply() {
    final q = ctrl.text.trim().toLowerCase();

    final base = all.where((c) => c.alarmaArmada == showArmadas).toList();

    if (q.isEmpty) {
      filtered = List.of(base);
    } else {
      filtered =
          base.where((c) => c.cliente.toLowerCase().contains(q)).toList();
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: const Text("Casas", style: TextStyle(color: Colors.white)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _selectorArmado(),
                  const SizedBox(height: 12),
                  _search(),
                  const SizedBox(height: 12),
                  ...filtered.map(_cardCasa),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text("No hay resultados",
                          style: TextStyle(color: Colors.white54)),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _selectorArmado() {
    final armadas = all.where((c) => c.alarmaArmada).length;
    final desarmadas = all.length - armadas;

    Widget card({
      required String title,
      required int count,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Colors.blueAccent.withOpacity(0.45)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  title.contains("Armadas")
                      ? Icons.shield
                      : Icons.shield_outlined,
                  color: selected ? Colors.blueAccent.shade100 : Colors.white70,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        card(
          title: "Casas Armadas",
          count: armadas,
          selected: showArmadas == true,
          onTap: () {
            if (showArmadas == true) return;
            setState(() => showArmadas = true);
            _apply();
          },
        ),
        const SizedBox(width: 12),
        card(
          title: "Casas Desarmadas",
          count: desarmadas,
          selected: showArmadas == false,
          onTap: () {
            if (showArmadas == false) return;
            setState(() => showArmadas = false);
            _apply();
          },
        ),
      ],
    );
  }

  Widget _search() {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Buscar por cliente...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _cardCasa(CasaGuardia c) {
    final dir = "${c.calle} ${c.numero}".trim();

    final status = c.dispositivoOnline ? "ONLINE" : "OFFLINE";
    final statusColor =
        c.dispositivoOnline ? Colors.greenAccent : Colors.redAccent;

    final puertaTxt = c.puertaEstado == "SIN_DATO"
        ? "PUERTA: ?"
        : (c.puertaAbierta ? "PUERTA ABIERTA" : "PUERTA CERRADA");
    final puertaColor = c.puertaEstado == "SIN_DATO"
        ? Colors.white70
        : (c.puertaAbierta ? Colors.greenAccent : Colors.redAccent);

    final ult = c.ultimoEvento;
    final ultHora = c.fechaUltimoEvento == null
        ? ""
        : "${c.fechaUltimoEvento!.hour.toString().padLeft(2, '0')}:${c.fechaUltimoEvento!.minute.toString().padLeft(2, '0')}";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuardiaCasaDetallePage(api: widget.api, casa: c),
          ),
        );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.cliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [dir, c.barrio].where((x) => x.trim().isNotEmpty).join(" · "),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),

            // ✅ ANTES era Row(...) -> causaba overflow
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(puertaTxt, puertaColor),
                _chip(status, statusColor),
                _chip(c.alarmaArmada ? "ARMADA" : "DESARMADA",
                    c.alarmaArmada ? Colors.orangeAccent : Colors.white70),
                _chip("NO LEÍDOS: ${c.eventosNoLeidos}", Colors.white),
              ],
            ),

            if (ult != null) ...[
              const SizedBox(height: 10),
              Text(
                ultHora.isEmpty ? "Último: $ult" : "Último: $ult · $ultHora",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
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
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
