import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class ContactosPage extends StatefulWidget {
  final ApiClient api;
  const ContactosPage({super.key, required this.api});

  @override
  State<ContactosPage> createState() => _ContactosPageState();
}

class _ContactosPageState extends State<ContactosPage> {
  bool loading = true;
  List<Map<String, dynamic>> contactos = [];

  String _prefijo = "+598"; // prefijo por defecto

  @override
  void initState() {
    super.initState();
    _loadContactos();
  }

  // ===========================================
  // Cargar contactos del backend
  // ===========================================
  Future<void> _loadContactos() async {
    try {
      final meResp = await widget.api.get("/api/me");
      final userId = meResp["id"];

      final resp = await widget.api.get("/api/contactos/usuario/$userId");

      setState(() {
        contactos = List<Map<String, dynamic>>.from(resp);
        loading = false;
      });
    } catch (e) {
      print("ERROR al cargar contactos → $e");
      setState(() => loading = false);
    }
  }

  // ===========================================
  // Crear o editar contacto
  // ===========================================
  Future<void> _openForm({Map<String, dynamic>? contacto}) async {
    String telefonoOriginal = contacto?["telefono"] ?? "";

    // Detectar prefijo si estamos editando
    if (telefonoOriginal.startsWith("+549")) {
      _prefijo = "+549";
      telefonoOriginal = telefonoOriginal.replaceFirst("+549", "");
      // remover el "9" inicial extra argentino
      if (telefonoOriginal.startsWith("9")) {
        telefonoOriginal = telefonoOriginal.substring(1);
      }
    } else if (telefonoOriginal.startsWith("+598")) {
      _prefijo = "+598";
      telefonoOriginal = telefonoOriginal.replaceFirst("+598", "");
    }

    final nombreCtrl = TextEditingController(text: contacto?["nombre"]);
    final telefonoCtrl = TextEditingController(text: telefonoOriginal);
    final relacionCtrl = TextEditingController(text: contacto?["relacion"]);

    final isEdit = contacto != null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(
          isEdit ? "Editar contacto" : "Nuevo contacto",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(nombreCtrl, "Nombre"),
            const SizedBox(height: 10),

            // Campo de teléfono con prefijo de país
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButton<String>(
                    value: _prefijo,
                    dropdownColor: const Color(0xFF1C1C1E),
                    underline: Container(),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: "+598", child: Text("🇺🇾 +598")),
                      DropdownMenuItem(value: "+549", child: Text("🇦🇷 +549")),
                    ],
                    onChanged: (v) {
                      setState(() => _prefijo = v!);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Teléfono",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blueAccent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),
            _campo(relacionCtrl, "Relación (opcional)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty || telefonoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Completa todos los campos")));
                return;
              }

              String raw = telefonoCtrl.text
                  .replaceAll(" ", "")
                  .replaceAll("-", "")
                  .trim();

              // =======================
              // FORMATEO AUTOMÁTICO
              // =======================
              String telefonoFinal = "";

              if (_prefijo == "+598") {
                // Uruguay → remover 0 inicial
                if (raw.startsWith("0")) raw = raw.substring(1);
                telefonoFinal = "+598$raw";
              }

              if (_prefijo == "+549") {
                // Argentina → agregar "9" si no está
                if (!raw.startsWith("9")) raw = "9$raw";
                telefonoFinal = "+549$raw";
              }

              try {
                if (isEdit) {
                  await widget.api.put(
                    "/api/contactos/${contacto!['id']}",
                    data: {
                      "nombre": nombreCtrl.text.trim(),
                      "telefono": telefonoFinal,
                      "relacion": relacionCtrl.text.trim(),
                    },
                  );
                } else {
                  if (contactos.length >= 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Máximo 2 contactos permitidos")),
                    );
                    return;
                  }

                  await widget.api.post(
                    "/api/contactos",
                    data: {
                      "nombre": nombreCtrl.text.trim(),
                      "telefono": telefonoFinal,
                      "relacion": relacionCtrl.text.trim(),
                    },
                  );
                }

                Navigator.pop(context);
                await _loadContactos();
              } catch (e) {
                print("ERROR al guardar → $e");
              }
            },
            child: const Text(
              "Guardar",
              style: TextStyle(color: Colors.blueAccent),
            ),
          )
        ],
      ),
    );
  }

  // ===========================================
  // Eliminar contacto
  // ===========================================
  Future<void> _delete(int id) async {
    try {
      await widget.api.delete("/api/contactos/$id");
      await _loadContactos();
    } catch (e) {
      print("ERROR eliminando contacto → $e");
    }
  }

  // ===========================================
  // UI
  // ===========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        title: const Text(
          "Contactos",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // ← FLECHA BLANCA
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : contactos.isEmpty
              ? const Center(
                  child: Text(
                    "Sin contactos",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: contactos.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (_, i) {
                    final c = contactos[i];
                    return _contactoCard(c);
                  },
                ),
    );
  }

  Widget _contactoCard(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.blueAccent.shade100, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c["nombre"],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  c["telefono"],
                  style: const TextStyle(color: Colors.white70),
                ),
                if ((c["relacion"] ?? "").toString().isNotEmpty)
                  Text(
                    c["relacion"],
                    style: const TextStyle(color: Colors.white54),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            onPressed: () => _openForm(contacto: c),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _delete(c["id"]),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
