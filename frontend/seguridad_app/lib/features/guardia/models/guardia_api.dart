import '../../../core/api/api_client.dart';
import '../models/panel_guardia.dart';
import '../models/evento_guardia.dart';
import '../models/casa_guardia.dart';

class GuardiaApi {
  final ApiClient api;
  GuardiaApi(this.api);

  Future<PanelGuardiaData> cargarPanel() async {
    final resp = await api.get('/api/guardia/panel');
    return PanelGuardiaData.fromJson(resp);
  }

  Future<List<CasaGuardia>> listarCasas() async {
    final resp = await api.get('/api/guardia/casas');
    if (resp is! List) return [];
    return resp
        .map((e) => CasaGuardia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<EventoGuardia>> listarEventos({int? casaId}) async {
    final url = casaId == null
        ? '/api/guardia/eventos'
        : '/api/guardia/eventos?casaId=$casaId';
    final resp = await api.get(url);
    if (resp is! List) return [];
    return resp
        .map((e) => EventoGuardia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> marcarLeido(int eventoId) async {
    await api.post('/api/guardia/eventos/$eventoId/leido');
  }

  Future<void> marcarAtendido(int eventoId) async {
    await api.post('/api/guardia/eventos/$eventoId/atendido');
  }

  Future<void> marcarLote({
    required List<int> ids,
    bool leido = false,
    bool atendido = false,
  }) async {
    await api.post('/api/guardia/eventos/marcar-lote', data: {
      'ids': ids,
      'leido': leido,
      'atendido': atendido,
    });
  }

  Future<void> marcarTodoCasa(int casaId) async {
    await api.post('/api/guardia/casas/$casaId/marcar-todo');
  }
}
