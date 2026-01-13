class AdminUsuario {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? telefono;
  final String rol;
  final bool activo;

  AdminUsuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.activo,
  });

  String get nombreCompleto => "${nombre.trim()} ${apellido.trim()}".trim();

  factory AdminUsuario.fromJson(Map<String, dynamic> json) {
    return AdminUsuario(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] ?? "").toString(),
      apellido: (json['apellido'] ?? "").toString(),
      email: (json['email'] ?? "").toString(),
      telefono: json['telefono']?.toString(),
      rol: (json['rol'] ?? "").toString(),
      activo: json['activo'] == true,
    );
  }

  Map<String, dynamic> toCreateJson({required String password}) {
    return {
      "nombre": nombre,
      "apellido": apellido,
      "email": email,
      "telefono": telefono,
      "password": password,
      "rol": rol,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      "nombre": nombre,
      "apellido": apellido,
      "telefono": telefono,
      "rol": rol,
      "activo": activo,
    };
  }
}
