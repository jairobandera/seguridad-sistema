class DispositivoEvento {
  final String deviceId;
  final String? nombre;
  final bool online;

  DispositivoEvento({
    required this.deviceId,
    this.nombre,
    required this.online,
  });

  factory DispositivoEvento.fromJson(Map<String, dynamic> json) {
    return DispositivoEvento(
      deviceId: json['deviceId'],
      nombre: json['nombre'],
      online: json['online'] == true,
    );
  }
}
