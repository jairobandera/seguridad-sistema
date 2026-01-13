import 'evento_guardia.dart';

class CasaEstadoGuardia {
  final int casaId;
  final String nombre;
  final String? barrio;

  final bool alarmaArmada;
  final bool dispositivoOnline;

  final int eventosNoLeidos;
  final EventoGuardia? ultimoEvento;

  CasaEstadoGuardia({
    required this.casaId,
    required this.nombre,
    this.barrio,
    required this.alarmaArmada,
    required this.dispositivoOnline,
    required this.eventosNoLeidos,
    this.ultimoEvento,
  });

  factory CasaEstadoGuardia.fromJson(Map<String, dynamic> json) {
    return CasaEstadoGuardia(
      casaId: json['casaId'],
      nombre: json['nombre'],
      barrio: json['barrio'],
      alarmaArmada: json['alarmaArmada'] == true,
      dispositivoOnline: json['dispositivoOnline'] == true,
      eventosNoLeidos: json['eventosNoLeidos'] ?? 0,
      ultimoEvento: json['ultimoEvento'] != null
          ? EventoGuardia.fromJson(json['ultimoEvento'])
          : null,
    );
  }
}
