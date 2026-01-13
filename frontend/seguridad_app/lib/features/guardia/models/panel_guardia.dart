import 'evento_guardia.dart';


class PanelGuardiaData {
  final List<EventoGuardia> eventosCriticos;
  final List<EventoGuardia> eventosNoLeidos;
  final List<EventoGuardia> ultimosEventos;
  final int dispositivosOffline;

  PanelGuardiaData({
    required this.eventosCriticos,
    required this.eventosNoLeidos,
    required this.ultimosEventos,
    required this.dispositivosOffline,
  });

  factory PanelGuardiaData.fromJson(Map<String, dynamic> json) {
    return PanelGuardiaData(
      eventosCriticos: _list(json['eventosCriticos']),
      eventosNoLeidos: _list(json['eventosNoLeidos']),
      ultimosEventos: _list(json['ultimosEventos']),
      dispositivosOffline: json['dispositivosOffline'] ?? 0,
    );
  }

  static List<EventoGuardia> _list(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => EventoGuardia.fromJson(e)).toList();
  }
}
