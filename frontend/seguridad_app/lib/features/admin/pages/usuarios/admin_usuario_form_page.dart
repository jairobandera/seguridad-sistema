import 'package:flutter/material.dart';

import '../../models/admin_usuario.dart';
import '../../services/admin_api.dart';

class AdminUsuarioFormPage extends StatefulWidget {
  final AdminApi api;
  final AdminUsuario? usuario; // null = crear

  const AdminUsuarioFormPage({
    super.key,
    required this.api,
    this.usuario,
  });

  @override
  State<AdminUsuarioFormPage> createState() => _AdminUsuarioFormPageState();
}

class _AdminUsuarioFormPageState extends State<AdminUsuarioFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nombreCtrl;
  late final TextEditingController apellidoCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController telefonoCtrl;
  final TextEditingController passCtrl = TextEditingController();

  String rol = "GUARDIA";
  bool activo = true;

  bool loading = false;
  bool showPass = false;

  bool get isEdit => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    final u = widget.usuario;
    nombreCtrl = TextEditingController(text: u?.nombre ?? "");
    apellidoCtrl = TextEditingController(text: u?.apellido ?? "");
    emailCtrl = TextEditingController(text: u?.email ?? "");
    telefonoCtrl = TextEditingController(text: u?.telefono ?? "");

    rol = u?.rol ?? "GUARDIA";
    activo = u?.activo ?? true;
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      if (isEdit) {
        await widget.api.actualizarUsuario(
          id: widget.usuario!.id,
          nombre: nombreCtrl.text.trim(),
          apellido: apellidoCtrl.text.trim(),
          telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
          rol: rol,
          activo: activo,
        );
      } else {
        await widget.api.crearUsuario(
          nombre: nombreCtrl.text.trim(),
          apellido: apellidoCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
          password: passCtrl.text.trim(),
          rol: rol,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isEdit ? "Editar usuario" : "Crear usuario";

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _input(
                            controller: nombreCtrl,
                            label: "Nombre",
                            icon: Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? "Requerido" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _input(
                            controller: apellidoCtrl,
                            label: "Apellido",
                            icon: Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? "Requerido" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: emailCtrl,
                      label: "Email",
                      icon: Icons.email_outlined,
                      enabled: !isEdit, // en v1: no editamos email
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Requerido";
                        if (!v.contains("@")) return "Email inválido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: telefonoCtrl,
                      label: "Teléfono (opcional)",
                      icon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _rolDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _activoSwitch()),
                      ],
                    ),

                    if (!isEdit) ...[
                      const SizedBox(height: 12),
                      _password(),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEdit ? "Guardar cambios" : "Crear usuario",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rolDropdown() {
    final roles = <String>["ADMIN", "GUARDIA", "CLIENTE"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: rol,
          dropdownColor: const Color(0xFF141416),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          items: roles
              .map((r) => DropdownMenuItem(value: r, child: Text("Rol: $r")))
              .toList(),
          onChanged: (v) => setState(() => rol = v ?? rol),
        ),
      ),
    );
  }

  Widget _activoSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: activo ? Colors.greenAccent : Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activo ? "Activo" : "Inactivo",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: activo,
            onChanged: (v) => setState(() => activo = v),
          ),
        ],
      ),
    );
  }

  Widget _password() {
    return TextFormField(
      controller: passCtrl,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Requerido";
        if (v.trim().length < 4) return "Mínimo 4 caracteres";
        return null;
      },
      obscureText: !showPass,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent.shade100),
        suffixIcon: IconButton(
          onPressed: () => setState(() => showPass = !showPass),
          icon: Icon(
            showPass ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.4),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.blueAccent.shade100),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.4),
        ),
      ),
    );
  }
}
