import 'casa_evento.dart';
import 'dispositivo_evento.dart';
import 'cliente_evento.dart';

class EventoGuardia {
  final int id;
  final String tipo;
  final String? severidad;
  final DateTime fecha;

  final CasaEvento? casa;
  final DispositivoEvento dispositivo;
  final ClienteEvento? cliente;

  final bool leido;
  final bool atendido;

  EventoGuardia({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.dispositivo,
    required this.leido,
    required this.atendido,
    this.severidad,
    this.casa,
    this.cliente,
  });

  factory EventoGuardia.fromJson(Map<String, dynamic> json) {
    final estado = json['estado'] as Map<String, dynamic>?;

    return EventoGuardia(
      id: json['id'],
      tipo: json['tipo'],
      severidad: json['severidad'],
      fecha: DateTime.parse(json['fecha'] ?? json['fechaHora']),
      dispositivo: DispositivoEvento.fromJson(json['dispositivo']),
      casa: json['casa'] != null ? CasaEvento.fromJson(json['casa']) : null,
      cliente:
          json['cliente'] != null ? ClienteEvento.fromJson(json['cliente']) : null,
      leido: estado?['leido'] == true,
      atendido: estado?['atendido'] == true,
    );
  }
}
