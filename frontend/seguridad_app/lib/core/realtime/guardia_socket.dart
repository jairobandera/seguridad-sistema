import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api/api_client.dart';
import '../notificacion/notification_service.dart';

class GuardiaSocket {
  GuardiaSocket._();
  static final GuardiaSocket _i = GuardiaSocket._();
  factory GuardiaSocket() => _i;

  IO.Socket? _socket;

  final _eventsCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _eventsCtrl.stream;

  Future<void> connect(String token) async {
    // si ya existe, actualizo auth y conecto si hace falta
    if (_socket != null) {
      _socket!.auth = {'token': token};
      if (!(_socket!.connected)) _socket!.connect();
      _bindHandlers();
      if (!(_socket!.connected)) _socket!.connect();
      return;
    }

    _socket = IO.io(
      ApiClient.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(800)
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('evento', (data) async {
      try {
        // =========================
        // 1) Mantener tu stream igual
        // =========================
        Map<String, dynamic>? ev;
        if (data is Map) {
          ev = Map<String, dynamic>.from(data);
          _eventsCtrl.add(ev);
        } else {
          _eventsCtrl.add({'raw': data});
        }

        // =========================
        // 2) Sonar alarma si PUERTA_ABIERTA
        // =========================
        final tipo = (ev?['tipo'] ?? '').toString();
        if (tipo == 'PUERTA_ABIERTA') {
          final title = '🚨 PUERTA ABIERTA';

          // body “lindo” (sin romper nada si no vienen campos)
          final casa = ev?['casa'];
          final cliente = ev?['cliente'];

          String casaTxt = '';
          if (casa is Map) {
            final calle = (casa['calle'] ?? '').toString();
            final numero = (casa['numero'] ?? casa['codigo'] ?? '').toString();
            final barrio = (casa['barrio'] ?? '').toString();
            casaTxt = [calle, numero, barrio]
                .where((x) => x.trim().isNotEmpty)
                .join(' ');
          }

          String cliTxt = '';
          if (cliente is Map) {
            final n = (cliente['nombre'] ?? '').toString();
            final a = (cliente['apellido'] ?? '').toString();
            cliTxt = '$n $a'.trim();
          }

          final body = [
            if (cliTxt.isNotEmpty) cliTxt,
            if (casaTxt.isNotEmpty) casaTxt,
          ].join(' · ');
          await NotificationService.showAlarmaPuerta(
            title,
            body.isEmpty ? 'Se detectó apertura de puerta.' : body,
          );
        }
      } catch (_) {}
    });

    _socket!.on('evento_estado_actualizado', (data) {
      if (data is Map) {
        _eventsCtrl.add({
          'tipo': 'EVENTO_ESTADO_ACTUALIZADO',
          ...Map<String, dynamic>.from(data),
        });
      }
    });

    _bindHandlers();
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void _bindHandlers() {
    if (_socket == null) return;

    // Evita duplicados si connect() se llama más de una vez
    _socket!.off('evento');
    _socket!.off('evento_estado_actualizado');

    // 1) Eventos de sensores (tu código actual)
    _socket!.on('evento', (data) async {
      try {
        Map<String, dynamic>? ev;
        if (data is Map) {
          ev = Map<String, dynamic>.from(data);
          _eventsCtrl.add(ev);
        } else {
          _eventsCtrl.add({'raw': data});
        }

        final tipo = (ev?['tipo'] ?? '').toString();
        if (tipo == 'PUERTA_ABIERTA') {
          final title = '🚨 PUERTA ABIERTA';

          final casa = ev?['casa'];
          final cliente = ev?['cliente'];

          String casaTxt = '';
          if (casa is Map) {
            final calle = (casa['calle'] ?? '').toString();
            final numero = (casa['numero'] ?? casa['codigo'] ?? '').toString();
            final barrio = (casa['barrio'] ?? '').toString();
            casaTxt = [calle, numero, barrio]
                .where((x) => x.trim().isNotEmpty)
                .join(' ');
          }

          String cliTxt = '';
          if (cliente is Map) {
            final n = (cliente['nombre'] ?? '').toString();
            final a = (cliente['apellido'] ?? '').toString();
            cliTxt = '$n $a'.trim();
          }

          final body = [
            if (cliTxt.isNotEmpty) cliTxt,
            if (casaTxt.isNotEmpty) casaTxt,
          ].join(' · ');

          await NotificationService.showAlarmaPuerta(
            title,
            body.isEmpty ? 'Se detectó apertura de puerta.' : body,
          );
        }
      } catch (_) {}
    });

    // 2) Estado actualizado (lo nuevo para sincronización)
    _socket!.on('evento_estado_actualizado', (data) {
      // DEBUG (dejalo un rato)
      print('SOCKET evento_estado_actualizado: $data');

      if (data is Map) {
        _eventsCtrl.add({
          'tipo': 'EVENTO_ESTADO_ACTUALIZADO',
          ...Map<String, dynamic>.from(data),
        });
      }
    });
  }
}
