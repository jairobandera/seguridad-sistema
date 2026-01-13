class CasaGuardia {
  final int id;
  final String cliente;
  final String barrio;
  final String calle;
  final String numero;
  final bool dispositivoOnline;
  final bool alarmaArmada;
  final int eventosNoLeidos;

  // puerta
  final bool puertaAbierta;
  final String puertaEstado; // ABIERTA / CERRADA / SIN_DATO

  // último evento (puerta)
  final String? ultimoEvento;
  final DateTime? fechaUltimoEvento;

  CasaGuardia({
    required this.id,
    required this.cliente,
    required this.barrio,
    required this.calle,
    required this.numero,
    required this.dispositivoOnline,
    required this.alarmaArmada,
    required this.eventosNoLeidos,
    required this.puertaAbierta,
    required this.puertaEstado,
    required this.ultimoEvento,
    required this.fechaUltimoEvento,
  });

  factory CasaGuardia.fromJson(Map<String, dynamic> json) {
    final ultimo = json['ultimoEvento'];

    final puertaEstado = (json['puertaEstado'] ?? 'SIN_DATO').toString();
    final puertaAbierta = json['puertaAbierta'] == true || puertaEstado == 'ABIERTA';

    return CasaGuardia(
      id: json['id'],
      cliente: (json['cliente'] ?? '').toString(),
      barrio: (json['barrio'] ?? '').toString(),
      calle: (json['calle'] ?? '').toString(),
      numero: (json['numero'] ?? '').toString(),
      dispositivoOnline: json['dispositivoOnline'] == true,
      alarmaArmada: json['alarmaArmada'] == true,
      eventosNoLeidos: (json['eventosNoLeidos'] ?? 0) as int,

      puertaAbierta: puertaAbierta,
      puertaEstado: puertaEstado,

      ultimoEvento: (ultimo is Map) ? (ultimo['tipo']?.toString()) : null,
      fechaUltimoEvento: (ultimo is Map && ultimo['fechaHora'] != null)
          ? DateTime.parse(ultimo['fechaHora'].toString()).toLocal()
          : null,
    );
  }
}
