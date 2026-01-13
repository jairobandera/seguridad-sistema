import 'package:flutter/material.dart';

import '../../models/admin_usuario.dart';
import '../../services/admin_api.dart';
import 'admin_usuario_form_page.dart';

class AdminUsuariosPage extends StatefulWidget {
  final AdminApi api;
  const AdminUsuariosPage({super.key, required this.api});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  bool loading = true;
  List<AdminUsuario> all = [];
  List<AdminUsuario> filtered = [];

  final searchCtrl = TextEditingController();
  String rolFilter = "TODOS";
  String estadoFilter = "TODOS"; // TODOS / ACTIVOS / INACTIVOS

  @override
  void initState() {
    super.initState();
    _load();
    searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final users = await widget.api.listarUsuarios();
    all = users;
    _applyFilters();
    if (!mounted) return;
    setState(() => loading = false);
  }

  void _applyFilters() {
    final q = searchCtrl.text.trim().toLowerCase();

    filtered = all.where((u) {
      final matchSearch = q.isEmpty ||
          u.nombre.toLowerCase().contains(q) ||
          u.apellido.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);

      final matchRol = rolFilter == "TODOS" || u.rol == rolFilter;

      final matchEstado = estadoFilter == "TODOS" ||
          (estadoFilter == "ACTIVOS" && u.activo) ||
          (estadoFilter == "INACTIVOS" && !u.activo);

      return matchSearch && matchRol && matchEstado;
    }).toList();

    // orden: activos arriba, luego por email
    filtered.sort((a, b) {
      final c1 = (b.activo ? 1 : 0) - (a.activo ? 1 : 0);
      if (c1 != 0) return c1;
      return a.email.compareTo(b.email);
    });

    if (mounted) setState(() {});
  }

  Future<void> _crearUsuario() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUsuarioFormPage(api: widget.api),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _editarUsuario(AdminUsuario u) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUsuarioFormPage(api: widget.api, usuario: u),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _deshabilitar(AdminUsuario u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141416),
        title: const Text("Deshabilitar usuario",
            style: TextStyle(color: Colors.white)),
        content: Text(
          "Se marcará como inactivo: ${u.email}",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text("Deshabilitar"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await widget.api.deshabilitarUsuario(u.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usuario deshabilitado ✅")),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E0F),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _table(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar por nombre / email...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _dropdownRol(),
          const SizedBox(width: 12),
          _dropdownEstado(),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _crearUsuario,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRol() {
    final roles = <String>["TODOS", "ADMIN", "GUARDIA", "CLIENTE"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: rolFilter,
          dropdownColor: const Color(0xFF141416),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: roles
              .map((r) => DropdownMenuItem(value: r, child: Text("Rol: $r")))
              .toList(),
          onChanged: (v) {
            rolFilter = v ?? "TODOS";
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _dropdownEstado() {
    final estados = <String>["TODOS", "ACTIVOS", "INACTIVOS"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: estadoFilter,
          dropdownColor: const Color(0xFF141416),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: estados
              .map((e) => DropdownMenuItem(value: e, child: Text("Estado: $e")))
              .toList(),
          onChanged: (v) {
            estadoFilter = v ?? "TODOS";
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _table() {
    if (filtered.isEmpty) {
      return const Center(
        child: Text("Sin resultados", style: TextStyle(color: Colors.white54)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
            dataTextStyle: const TextStyle(color: Colors.white),
            columns: const [
              DataColumn(label: Text("Activo")),
              DataColumn(label: Text("Nombre")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Rol")),
              DataColumn(label: Text("Teléfono")),
              DataColumn(label: Text("Acciones")),
            ],
            rows: filtered.map((u) {
              return DataRow(
                cells: [
                  DataCell(_chipActivo(u.activo)),
                  DataCell(Text(u.nombreCompleto)),
                  DataCell(Text(u.email)),
                  DataCell(_chipRol(u.rol)),
                  DataCell(Text(u.telefono ?? "-")),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _editarUsuario(u),
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        ),
                        IconButton(
                          onPressed: u.activo ? () => _deshabilitar(u) : null,
                          icon: const Icon(Icons.block, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _chipActivo(bool activo) {
    final txt = activo ? "ACTIVO" : "INACTIVO";
    final color = activo ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        txt,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _chipRol(String rol) {
    Color c = Colors.white70;
    if (rol == "ADMIN") c = Colors.orangeAccent;
    if (rol == "GUARDIA") c = Colors.blueAccent;
    if (rol == "CLIENTE") c = Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Text(
        rol,
        style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
