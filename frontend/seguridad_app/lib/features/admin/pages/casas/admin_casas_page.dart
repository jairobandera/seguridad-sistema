// lib/features/admin/pages/casas/admin_casas_page.dart
import 'package:flutter/material.dart';

import '../../models/admin_casa.dart';
import '../../services/admin_casas_api.dart';
import 'admin_casa_form_page.dart';

class AdminCasasPage extends StatefulWidget {
  final AdminCasasApi api;

  const AdminCasasPage({
    super.key,
    required this.api,
  });

  @override
  State<AdminCasasPage> createState() => _AdminCasasPageState();
}

class _AdminCasasPageState extends State<AdminCasasPage> {
  late final AdminCasasApi casasApi;

  bool loading = true;
  List<AdminCasa> all = [];
  List<AdminCasa> filtered = [];

  final TextEditingController ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    casasApi = widget.api; 
    ctrl.addListener(_apply);
    _load();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      all = await casasApi.listar();
      _apply();
    } catch (e) {
      // opcional: snackbar
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _apply() {
    final q = ctrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      filtered = List.of(all);
    } else {
      filtered = all.where((c) {
        final cliente = (c.clienteNombre ?? "").toLowerCase();
        final cod = (c.codigo ?? "").toLowerCase();
        final dir = c.direccion.toLowerCase();
        return cliente.contains(q) || cod.contains(q) || dir.contains(q);
      }).toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final created = await Navigator.push<AdminCasa?>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCasaFormPage()),
    );
    if (created == null) return;

    try {
      await casasApi.crear(created);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creando casa: $e")),
      );
    }
  }

  Future<void> _edit(AdminCasa c) async {
    final edited = await Navigator.push<AdminCasa?>(
      context,
      MaterialPageRoute(builder: (_) => AdminCasaFormPage(initial: c)),
    );
    if (edited == null) return;

    try {
      await casasApi.actualizar(c.id, edited);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error actualizando casa: $e")),
      );
    }
  }

  Future<void> _disable(AdminCasa c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1C),
        title: const Text("Deshabilitar casa",
            style: TextStyle(color: Colors.white)),
        content: Text(
          "¿Querés deshabilitar esta casa?\n\n${c.direccion.isEmpty ? "Casa #${c.id}" : c.direccion}",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Deshabilitar",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await casasApi.deshabilitar(c.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deshabilitando casa: $e")),
      );
    }
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
        actions: [
          IconButton(
            onPressed: _create,
            icon: const Icon(Icons.add, color: Colors.blueAccent),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _search(),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text("No hay resultados",
                          style: TextStyle(color: Colors.white54)),
                    )
                  else
                    ...filtered.map(_cardCasa),
                ],
              ),
            ),
    );
  }

  Widget _search() {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Buscar por cliente / código / dirección...",
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

  Widget _cardCasa(AdminCasa c) {
    final title =
        (c.clienteNombre != null && c.clienteNombre!.trim().isNotEmpty)
            ? c.clienteNombre!.trim()
            : (c.codigo != null && c.codigo!.trim().isNotEmpty)
                ? "Casa ${c.codigo}"
                : "Casa #${c.id}";

    final subtitle = c.direccion;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home_rounded,
            color: c.activo ? Colors.white : Colors.white38,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      c.alarmaArmada ? "ARMADA" : "DESARMADA",
                      c.alarmaArmada ? Colors.orangeAccent : Colors.white70,
                    ),
                    _chip(
                      c.activo ? "ACTIVA" : "DESHABILITADA",
                      c.activo ? Colors.greenAccent : Colors.redAccent,
                    ),
                    if (c.usuarioId != null)
                      _chip("Dueño: ${c.usuarioId}", Colors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              IconButton(
                onPressed: () => _edit(c),
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
              ),
              IconButton(
                onPressed: () => _disable(c),
                icon: const Icon(Icons.block, color: Colors.redAccent),
              ),
            ],
          ),
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
