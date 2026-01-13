// lib/features/admin/pages/casas/admin_casa_form_page.dart
import 'package:flutter/material.dart';
import '../../models/admin_casa.dart';

class AdminCasaFormPage extends StatefulWidget {
  final AdminCasa? initial;
  const AdminCasaFormPage({super.key, this.initial});

  @override
  State<AdminCasaFormPage> createState() => _AdminCasaFormPageState();
}

class _AdminCasaFormPageState extends State<AdminCasaFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigoCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _calleCtrl;
  late final TextEditingController _barrioCtrl;
  late final TextEditingController _manzanaCtrl;
  late final TextEditingController _usuarioIdCtrl;

  bool _alarmaArmada = false;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;

    _codigoCtrl = TextEditingController(text: c?.codigo ?? "");
    _numeroCtrl = TextEditingController(text: c?.numero ?? "");
    _calleCtrl = TextEditingController(text: c?.calle ?? "");
    _barrioCtrl = TextEditingController(text: c?.barrio ?? "");
    _manzanaCtrl = TextEditingController(text: c?.manzana ?? "");
    _usuarioIdCtrl = TextEditingController(text: c?.usuarioId?.toString() ?? "");

    _alarmaArmada = c?.alarmaArmada ?? false;
    _activo = c?.activo ?? true;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _numeroCtrl.dispose();
    _calleCtrl.dispose();
    _barrioCtrl.dispose();
    _manzanaCtrl.dispose();
    _usuarioIdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    int? usuarioId;
    final rawUserId = _usuarioIdCtrl.text.trim();
    if (rawUserId.isNotEmpty) {
      usuarioId = int.tryParse(rawUserId);
    }

    final casa = AdminCasa(
      id: widget.initial?.id ?? 0, // el id real lo pone el backend al crear
      codigo: _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim(),
      numero: _numeroCtrl.text.trim().isEmpty ? null : _numeroCtrl.text.trim(),
      calle: _calleCtrl.text.trim().isEmpty ? null : _calleCtrl.text.trim(),
      barrio: _barrioCtrl.text.trim().isEmpty ? null : _barrioCtrl.text.trim(),
      manzana: _manzanaCtrl.text.trim().isEmpty ? null : _manzanaCtrl.text.trim(),
      usuarioId: usuarioId,
      alarmaArmada: _alarmaArmada,
      activo: _activo,
    );

    Navigator.pop(context, casa);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0E0E0F),
        elevation: 0,
        title: Text(isEdit ? "Editar Casa" : "Crear Casa",
            style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(_codigoCtrl, "Código (opcional)"),
              const SizedBox(height: 12),
              _input(_numeroCtrl, "Número (opcional)"),
              const SizedBox(height: 12),
              _input(_calleCtrl, "Calle (opcional)"),
              const SizedBox(height: 12),
              _input(_barrioCtrl, "Barrio (opcional)"),
              const SizedBox(height: 12),
              _input(_manzanaCtrl, "Manzana (opcional)"),
              const SizedBox(height: 12),
              _input(
                _usuarioIdCtrl,
                "Usuario ID (dueño) (opcional)",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),

              _switchRow(
                title: "Alarma armada",
                value: _alarmaArmada,
                onChanged: (v) => setState(() => _alarmaArmada = v),
              ),
              const SizedBox(height: 8),
              _switchRow(
                title: "Activo",
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEdit ? "Guardar cambios" : "Crear",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }
}
