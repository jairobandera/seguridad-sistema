import '../../../core/api/api_client.dart';
import '../models/admin_usuario.dart';

class AdminApi {
  final ApiClient api;
  AdminApi(this.api);

  Future<List<AdminUsuario>> listarUsuarios() async {
    final resp = await api.get('/api/usuarios');
    if (resp is! List) return [];
    return resp
        .map((e) => AdminUsuario.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdminUsuario> crearUsuario({
    required String nombre,
    required String apellido,
    required String email,
    String? telefono,
    required String password,
    required String rol,
  }) async {
    final resp = await api.post('/api/usuarios', data: {
      "nombre": nombre,
      "apellido": apellido,
      "email": email,
      "telefono": telefono,
      "password": password,
      "rol": rol,
    });

    // backend devuelve usuario creado (prisma)
    return AdminUsuario.fromJson(Map<String, dynamic>.from(resp));
  }

  Future<AdminUsuario> actualizarUsuario({
    required int id,
    String? nombre,
    String? apellido,
    String? telefono,
    String? rol,
    bool? activo,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data["nombre"] = nombre;
    if (apellido != null) data["apellido"] = apellido;
    if (telefono != null) data["telefono"] = telefono;
    if (rol != null) data["rol"] = rol;
    if (activo != null) data["activo"] = activo;

    final resp = await api.put('/api/usuarios/$id', data: data);
    return AdminUsuario.fromJson(Map<String, dynamic>.from(resp));
  }

  Future<void> deshabilitarUsuario(int id) async {
    await api.delete('/api/usuarios/$id');
  }
}
