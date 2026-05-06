import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/realtime/device_socket.dart';
import '../../../core/storage/session_manager.dart';

class WifiPage extends StatefulWidget {
  final String casaNombre;
  final bool dispositivoOnline;
  final String? deviceId;

  const WifiPage({
    super.key,
    required this.casaNombre,
    required this.dispositivoOnline,
    this.deviceId,
  });

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  final TextEditingController _ssidCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _working = false;
  String _estado = '';
  String _estadoColor = 'normal';
  String _deviceWifi = '';
  String _realDeviceId = '';

  final _ble = FlutterReactiveBle();
  DiscoveredDevice? _selectedDevice;
  late Uuid _nusService = Uuid.parse('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  late Uuid _nusRx    = Uuid.parse('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');
  late Uuid _nusTx    = Uuid.parse('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');
  late Uuid _nusId    = Uuid.parse('6E400004-B5A3-F393-E0A9-E50E24DCCA9E');
  QualifiedCharacteristic? _writeChar;
  QualifiedCharacteristic? _readIdChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  Completer<void>? _wifiConnectCompleter;
  Completer<void>? _factoryResetCompleter;
  String _bleBuffer = '';
  
  // Socket.IO y polling
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _pollingTimer;
  String? _authToken;

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    _notifySub?.cancel();
    _connection?.cancel();
    _socketSub?.cancel();
    _pollingTimer?.cancel();
    DeviceSocket().disconnect();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Si tenemos deviceId del widget, usarlo inmediatamente
    if (widget.deviceId != null && widget.deviceId!.isNotEmpty) {
      _realDeviceId = widget.deviceId!;
      // Fetch INMEDIATO del estado desde la DB
      _fetchDeviceStatus();
      // Cargar último SSID conocido de persistencia
      _loadLastKnownSsid();
    }
    
    _loadPairedDevice();
    _initSocket();
  }
  
  void _initSocket() async {
    _authToken = await SessionManager.getToken();
    if (_authToken == null) return;
    
    DeviceSocket().connect(_authToken!);
    
    _socketSub = DeviceSocket().statusStream.listen((data) {
      final ssid = data['ssid'] as String?;
      final status = data['status'] as String?;
      final wifi = data['wifi'] as bool?;
      
      // 🔥 Limpiar cuando wifi=false o status=ERROR
      if (wifi == false || status == 'ERROR_WIFI' || status == 'WIFI_DISCONNECTED') {
        _clearLastKnownSsid();
        if (mounted) {
          setState(() {
            _deviceWifi = '';
            _estado = 'Dispositivo NO conectado al WiFi';
            _estadoColor = 'error';
          });
        }
        debugPrint('Socket device:status: $data');
        return;
      }
      
      // Guardar SSID conocido en persistencia
      if (ssid != null && ssid.isNotEmpty && (status == 'WIFI_CONNECTED' || status == 'MQTT_CONNECTED')) {
        _saveLastKnownSsid(ssid);
        if (mounted) {
          setState(() {
            _deviceWifi = ssid;
            _estado = 'Conectado a $ssid';
            _estadoColor = 'ok';
          });
        }
      }
      
      debugPrint('Socket device:status: $data');
    });
    
    _startPolling();
  }
  
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_realDeviceId.isNotEmpty) {
        _fetchDeviceStatus();
      }
    });
  }
  
  // 🔥 FIX 4: Polling agresivo por 30 segundos después de factory reset
  void _startRapidPolling() {
    _pollingTimer?.cancel();
    int count = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      count++;
      _fetchDeviceStatus();
      if (count >= 15) {  // 30 segundos totales (15 * 2s)
        timer.cancel();
        _startPolling();  // Volver a polling normal (cada 5s)
      }
    });
  }
  
  Future<void> _fetchDeviceStatus() async {
    if (_realDeviceId.isEmpty) return;
    try {
      final response = await ApiClient().get('/api/dispositivos/$_realDeviceId/wifi-status');
      if (response is Map && response['ok'] == true) {
        final data = response['data'] as Map;
        final ssid = data['wifiSsid'] as String?;
        final online = data['online'] as bool?;
        
        if (mounted) {
          // 🔥 Si está offline, limpiar SSID persistido
          if (online == false) {
            _clearLastKnownSsid();
          }
          
          setState(() {
            _deviceWifi = ssid ?? '';
            _estado = ssid != null && ssid.isNotEmpty 
                ? 'Conectado a $ssid' 
                : (online == true ? 'En línea (sin WiFi config)' : 'Offline');
            _estadoColor = ssid != null && ssid.isNotEmpty ? 'ok' : 'error';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching device status: $e');
    }
  }
  
  Future<void> _loadLastKnownSsid() async {
    if (_realDeviceId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ssid = prefs.getString('last_known_ssid_$_realDeviceId');
      if (ssid != null && ssid.isNotEmpty && _deviceWifi.isEmpty) {
        setState(() {
          _deviceWifi = ssid;
          _estado = 'Conectado a $ssid (último conocido)';
          _estadoColor = 'ok';
        });
      }
    } catch (e) {
      debugPrint('Error loading last known SSID: $e');
    }
  }
  
  Future<void> _saveLastKnownSsid(String ssid) async {
    if (_realDeviceId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_known_ssid_$_realDeviceId', ssid);
    } catch (e) {
      debugPrint('Error saving last known SSID: $e');
    }
  }
  
  Future<void> _clearLastKnownSsid() async {
    if (_realDeviceId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_known_ssid_$_realDeviceId');
      debugPrint('SSID persistido eliminado para $_realDeviceId');
    } catch (e) {
      debugPrint('Error clearing last known SSID: $e');
    }
  }

  // =====================================================
  // ENVIO BLE FRAGMENTADO
  // =====================================================
  Future<void> _writeBle(String jsonStr) async {
    if (_writeChar == null) return;
    final bytes = utf8.encode(jsonStr);
    const chunkSize = 20;
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      await _ble.writeCharacteristicWithoutResponse(_writeChar!, value: bytes.sublist(i, end));
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // =====================================================
  // PROCESAR NOTIFICACIONES BLE
  // =====================================================
  void _onNotify(List<int> data) {
    final s = utf8.decode(data);
    _bleBuffer += s;

    // Procesar todos los mensajes completos en el buffer
    while (true) {
      // Buscar inicio de mensaje JSON
      int start = _bleBuffer.indexOf('{');
      if (start == -1) {
        // No hay inicio de JSON, limpiar buffer si es muy largo
        if (_bleBuffer.length > 100) _bleBuffer = '';
        break;
      }

      // Buscar fin de mensaje JSON
      int end = _bleBuffer.indexOf('}', start);
      if (end == -1) {
        // No hay fin de JSON aún
        if (_bleBuffer.length > 200) {
          _bleBuffer = _bleBuffer.substring(start);
        }
        break;
      }

      // Extraer mensaje completo
      String msg = _bleBuffer.substring(start, end + 1);
      _bleBuffer = _bleBuffer.substring(end + 1);

      debugPrint('BLE RX: $msg');
      _processMessage(msg);
    }
  }

  void _processMessage(String data) {
    try {
      final map = json.decode(data);
      if (map is! Map) return;

      // Resultado de conexión WiFi
      if (map['result'] == 'ok' && map['ssid'] != null) {
        final ssid = map['ssid'].toString();
        _wifiConnectCompleter?.complete();
        setState(() {
          _deviceWifi = ssid;
          _estado = 'Dispositivo conectado a $ssid';
          _estadoColor = 'ok';
        });
        _ssidCtrl.clear();
        _passCtrl.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSuccessDialog(ssid);
        });
        return;
      }

      // Error de conexión WiFi
      if (map['result'] == 'error') {
        final reason = map['reason'] ?? 'unknown';
        _wifiConnectCompleter?.complete();
        _factoryResetCompleter?.complete();
        _showErrorDialog('No se pudo conectar: $reason');
        return;
      }

      // Credenciales aceptadas
      if (map['result'] == 'accepted') {
        setState(() {
          _estado = 'Credenciales recibidas. Conectando...';
          _estadoColor = 'normal';
        });
        // No completamos el completer aqui, esperamos confirmacion por MQTT
        return;
      }

      // Credenciales borradas
      if (map['result'] == 'cleared') {
        _factoryResetCompleter?.complete();
        
        // 🔥 Limpiar inmediatamente y actualizar UI
        _clearLastKnownSsid();
        
        setState(() {
          _deviceWifi = '';
          _estado = 'Credenciales borradas en el dispositivo.';
          _estadoColor = 'ok';
        });
        _ssidCtrl.clear();
        _passCtrl.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showClearedDialog();
        });
        return;
      }

      // Estado WiFi (del comando status)
      if (map.containsKey('wifiConnected')) {
        final connected = map['wifiConnected'] == true || map['wifiConnected'] == 'true';
        final ssid = map['ssid']?.toString() ?? '';
        
        if (connected && ssid.isNotEmpty) {
          _saveLastKnownSsid(ssid);
          setState(() {
            _deviceWifi = ssid;
            _estado = 'Dispositivo conectado a $ssid';
            _estadoColor = 'ok';
          });
        } else {
          // 🔥 Limpiar SSID persistido cuando NO está conectado
          _clearLastKnownSsid();
          setState(() {
            _deviceWifi = '';
            _estado = 'Dispositivo NO conectado al WiFi';
            _estadoColor = 'error';
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('BLE parse error: $e');
    }
  }

  // =====================================================
  // CONEXION BLE
  // =====================================================
  Future<void> _disconnectBle() async {
    await _notifySub?.cancel();
    await _connection?.cancel();
    _notifySub = null;
    _connection = null;
    _selectedDevice = null;
    _writeChar = null;
    _bleBuffer = '';
  }

  Future<bool> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _estado = 'Conectando por BLE...';
      _estadoColor = 'normal';
      _working = true;
    });

    try {
      _connection = _ble.connectToDevice(
        id: device.id,
        servicesWithCharacteristicsToDiscover: {},
      ).listen((event) async {
        if (event.connectionState == DeviceConnectionState.connected) {
          _selectedDevice = device;
          _writeChar = QualifiedCharacteristic(
            serviceId: _nusService,
            characteristicId: _nusRx,
            deviceId: device.id,
          );
          _readIdChar = QualifiedCharacteristic(
            serviceId: _nusService,
            characteristicId: _nusId,
            deviceId: device.id,
          );
          final notifyChar = QualifiedCharacteristic(
            serviceId: _nusService,
            characteristicId: _nusTx,
            deviceId: device.id,
          );
          _notifySub = _ble.subscribeToCharacteristic(notifyChar).listen(_onNotify, onError: (_) {});

          // Leer deviceId
          try {
            final idData = await _ble.readCharacteristic(_readIdChar!);
            _realDeviceId = utf8.decode(idData);
            debugPrint('Device ID: $_realDeviceId');
            // Iniciar polling ahora que tenemos el deviceId
            _startPolling();
            _fetchDeviceStatus();
          } catch (_) {}

          setState(() {
            _estado = 'Conectado por BLE';
            _estadoColor = 'ok';
            _working = false;
          });
        }
        if (event.connectionState == DeviceConnectionState.disconnected) {
          setState(() {
            _estado = 'BLE desconectado';
            _estadoColor = 'error';
            _working = false;
          });
          _bleBuffer = '';
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      if (_writeChar == null) {
        await _disconnectBle();
        setState(() {
          _estado = 'Error de conexion BLE';
          _estadoColor = 'error';
          _working = false;
        });
        return false;
      }
      return true;
    } catch (e) {
      await _disconnectBle();
      setState(() {
        _estado = 'Error: $e';
        _estadoColor = 'error';
        _working = false;
      });
      return false;
    }
  }

  // =====================================================
  // ESCANEO
  // =====================================================
  Future<DiscoveredDevice?> _scanAndSelect() async {
    final status = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    final locationStatus = await Permission.location.request();

    if (!status.isGranted || !connectStatus.isGranted) {
      _showErrorDialog('Se necesitan permisos de Bluetooth');
      return null;
    }
    if (!locationStatus.isGranted) {
      _showErrorDialog('Se necesita permiso de ubicacion');
      return null;
    }

    final found = <String, DiscoveredDevice>{};
    setState(() {
      _estado = 'Escaneando...';
      _estadoColor = 'normal';
    });

    final sub = _ble.scanForDevices(withServices: [_nusService]).listen((device) {
      final name = device.name ?? '';
      if (name.contains('HUB-')) {
        found[device.id] = device;
      }
    });

    await Future.delayed(const Duration(seconds: 8));
    await sub.cancel();

    if (found.isEmpty) {
      setState(() {
        _estado = 'No se encontro HUB';
        _estadoColor = 'error';
      });
      return null;
    }

    final items = found.values.toList();
    final selected = await showModalBottomSheet<DiscoveredDevice>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Selecciona tu dispositivo HUB',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            for (final r in items)
              ListTile(
                tileColor: const Color(0xFF0E0E0F),
                leading: const Icon(Icons.router, color: Colors.blueAccent),
                title: Text(r.name.isNotEmpty ? r.name : r.id,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text('${r.rssi} dBm',
                    style: const TextStyle(color: Colors.white70)),
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    );

    return selected;
  }

  // =====================================================
  // PERSISTENCIA
  // =====================================================
  Future<void> _savePairedDevice(DiscoveredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paired_device_id', device.id);
    await prefs.setString('paired_device_name', device.name ?? '');
  }

  Future<void> _loadPairedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('paired_device_id');
    if (id == null) return;

    setState(() {
      _estado = 'Reconectando...';
      _working = true;
    });

    final found = <String, DiscoveredDevice>{};
    final sub = _ble.scanForDevices(withServices: [_nusService]).listen((r) {
      if (r.id == id) found[r.id] = r;
    });

    await Future.delayed(const Duration(seconds: 5));
    await sub.cancel();

    final dev = found[id];
    if (dev != null) {
      final ok = await _connectToDevice(dev);
      if (ok) {
        setState(() {
          _selectedDevice = dev;
          _estado = 'Emparejado';
          _estadoColor = 'ok';
        });
      } else {
        setState(() {
          _estado = 'No se pudo reconectar';
          _estadoColor = 'error';
        });
      }
    } else {
      setState(() {
        _estado = 'Dispositivo no encontrado';
        _estadoColor = 'error';
      });
    }
    setState(() { _working = false; });
  }

  // =====================================================
  // ENVIAR CREDENCIALES
  // =====================================================
  Future<void> _sendCredentials() async {
    final ssid = _ssidCtrl.text.trim();
    final pass = _passCtrl.text;
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el SSID')));
      return;
    }

    setState(() {
      _working = true;
      _estado = 'Enviando credenciales...';
      _estadoColor = 'normal';
    });

    DiscoveredDevice? device = _selectedDevice;
    if (device == null) {
      device = await _scanAndSelect();
      if (device == null) {
        setState(() { _working = false; });
        return;
      }
    }

    final ok = await _connectToDevice(device);
    if (!ok) return;

    _wifiConnectCompleter = Completer<void>();
    final timeout = Timer(const Duration(seconds: 35), () {
      if (!_wifiConnectCompleter!.isCompleted) {
        _wifiConnectCompleter!.complete();
      }
    });

    try {
      await _writeBle(json.encode({'cmd': 'wifi', 'ssid': ssid, 'pass': pass}));
      await _wifiConnectCompleter!.future;
      timeout.cancel();

      if (!mounted) return;

      if (_deviceWifi.isEmpty) {
        _showErrorDialog('No se recibio confirmacion. Verifica la contrasena.');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Error: $e');
    } finally {
      timeout.cancel();
      if (mounted) {
        setState(() { _working = false; });
        await _disconnectBle();
      }
    }
  }

  // =====================================================
  // FACTORY RESET
  // =====================================================
  Future<void> _factoryReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar credenciales'),
        content: const Text('Esto eliminara las credenciales WiFi guardadas en la placa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _working = true;
      _estado = 'Borrando credenciales...';
      _estadoColor = 'normal';
    });

    try {
      DiscoveredDevice? device = _selectedDevice;
      
      // 🔥 Intentar BLE PRIMERO (incluso si dispositivo está offline)
      if (device == null) {
        device = await _scanAndSelect();
        if (device == null) {
          setState(() {
            _estado = 'No se selecciono dispositivo';
            _estadoColor = 'error';
            _working = false;
          });
          return;
        }
      }

      final ok = await _connectToDevice(device);
      if (ok) {
        // Enviar por BLE
        _factoryResetCompleter = Completer<void>();
        final timeout = Timer(const Duration(seconds: 10), () {
          if (!_factoryResetCompleter!.isCompleted) {
            _factoryResetCompleter!.complete();
          }
        });

        await _writeBle(json.encode({'cmd': 'clear_wifi'}));
        await _factoryResetCompleter!.future;
        timeout.cancel();
        
        // 🔥 FIX 1: Limpiar persistencia y actualizar UI INMEDIATAMENTE
        _clearLastKnownSsid();
        
        if (mounted) {
          setState(() {
            _working = false;
            _estado = 'Credenciales borradas. El dispositivo se reiniciará...';
            _estadoColor = 'ok';
            _deviceWifi = '';  // Limpiar WiFi mostrado
          });
        }
        
        // 🔥 FIX 4: Polling agresivo por 30 segundos
        _startRapidPolling();
        
        await _disconnectBle();
        return;  // ✅ Éxito por BLE, no intentar MQTT
      }
      
      // Si BLE falló y dispositivo está online, intentar por MQTT
      if (widget.dispositivoOnline && widget.deviceId != null) {
        try {
          final response = await ApiClient().post(
            '/api/dispositivos/${widget.deviceId}/factory-reset',
          );
          
          if (mounted && response is Map && response['ok'] == true) {
            _clearLastKnownSsid();
            
            // 🔥 FIX 1: Actualizar UI inmediatamente
            setState(() {
              _working = false;
              _estado = 'Comando de reset enviado. El dispositivo se reiniciará...';
              _estadoColor = 'ok';
              _deviceWifi = '';
            });
            
            // 🔥 FIX 4: Polling agresivo
            _startRapidPolling();
          }
        } catch (mqttError) {
          debugPrint('Error factory reset por MQTT: $mqttError');
          if (mounted) {
            setState(() {
              _working = false;
              _estado = 'Error: No se pudo conectar por BLE ni MQTT';
              _estadoColor = 'error';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _working = false;
            _estado = 'Error: No se pudo conectar al dispositivo';
            _estadoColor = 'error';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estado = 'Error: $e';
          _estadoColor = 'error';
          _working = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() { _working = false; });
        await _disconnectBle();
      }
    }
  }

  // =====================================================
  // DIALOGOS
  // =====================================================
  void _showSuccessDialog(String ssid) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conexion establecida'),
        content: Text('La placa se conecto a "$ssid"'),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'))],
      ),
    );
  }

  void _showClearedDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Credenciales borradas'),
        content: const Text('La placa ha eliminado las credenciales WiFi.'),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'))],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'))],
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0F),
        title: const Text('Configuracion WiFi'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dispositivo', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(widget.casaNombre,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(
                    widget.dispositivoOnline ? Icons.check_circle : Icons.cancel,
                    color: widget.dispositivoOnline ? Colors.greenAccent : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.dispositivoOnline ? 'Online (MQTT)' : 'Offline',
                    style: const TextStyle(color: Colors.white),
                  ),
                ]),
                const SizedBox(height: 10),
                if (widget.deviceId != null)
                  ElevatedButton.icon(
                    onPressed: _working ? null : _factoryReset,
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Resetear de fabrica'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  ),
              ],
            )),

            const SizedBox(height: 20),

            const Text(
              'Usa redes 2.4 GHz (NO 5G). Acerca el celular a la placa.',
              style: TextStyle(color: Colors.yellowAccent, fontSize: 13),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _working ? null : () async {
                  setState(() { _working = true; _estado = 'Escaneando...'; });
                  final device = await _scanAndSelect();
                  if (device == null) {
                    setState(() { _working = false; });
                    return;
                  }
                  final ok = await _connectToDevice(device);
                  if (ok) {
                    await _savePairedDevice(device);
                    setState(() {
                      _selectedDevice = device;
                      _estado = 'Emparejado';
                      _estadoColor = 'ok';
                    });
                  }
                  setState(() { _working = false; });
                },
                icon: const Icon(Icons.bluetooth),
                label: Text(_selectedDevice == null
                    ? 'Emparejar con placa'
                    : 'Emparejado: ${_selectedDevice!.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('WiFi del dispositivo:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                _deviceWifi.isNotEmpty ? _deviceWifi : 'No conectado',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ])),

            const SizedBox(height: 12),

            _card(child: Column(children: [
              TextField(
                controller: _ssidCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'SSID (nombre de la red 2.4GHz)',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E).withOpacity(0.6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contrasena',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E).withOpacity(0.6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _working ? null : _sendCredentials,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _working
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Enviar credenciales y conectar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ])),

                if (_estado.isNotEmpty)
                  _card(child: Row(children: [
                    Icon(
                      _estadoColor == 'ok' ? Icons.check_circle
                          : _estadoColor == 'error' ? Icons.error_outline
                          : Icons.info_outline,
                      color: _estadoColor == 'ok' ? Colors.greenAccent
                          : _estadoColor == 'error' ? Colors.redAccent
                          : Colors.white60,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_estado, style: const TextStyle(color: Colors.white70))),
                  ])),
          ],
        ),
      ),
    );
  }
}
