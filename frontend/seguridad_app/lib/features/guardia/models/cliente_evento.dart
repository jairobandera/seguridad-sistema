class ClienteEvento {
  final int id;
  final String nombre;
  final String apellido;
  final String? telefono;

  ClienteEvento({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.telefono,
  });

  factory ClienteEvento.fromJson(Map<String, dynamic> json) {
    return ClienteEvento(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      telefono: json['telefono'],
    );
  }
}
