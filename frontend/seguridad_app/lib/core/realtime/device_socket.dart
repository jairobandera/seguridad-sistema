import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api/api_client.dart';

class DeviceSocket {
  DeviceSocket._();
  static final DeviceSocket _i = DeviceSocket._();
  factory DeviceSocket() => _i;

  IO.Socket? _socket;
  final _statusCtrl = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get statusStream => _statusCtrl.stream;
  bool get connected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null) {
      _socket!.auth = {'token': token};
      if (!(_socket!.connected)) _socket!.connect();
      _bindHandlers();
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

    _bindHandlers();
    _socket!.connect();
  }

  void _bindHandlers() {
    if (_socket == null) return;

    _socket!.off('device:status');
    _socket!.off('device:updated');

    _socket!.on('device:status', (data) {
      if (data is Map) {
        _statusCtrl.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('device:updated', (data) {
      if (data is Map) {
        _statusCtrl.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _statusCtrl.close();
    disconnect();
  }
}
