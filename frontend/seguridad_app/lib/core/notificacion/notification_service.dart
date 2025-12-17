import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel alarmaChannel =
      AndroidNotificationChannel(
    'alarma_puerta_v2',
    'Alerta de Puerta',
    description: 'Canal para alertas de seguridad con sonido alarma.mp3',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarma'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
  );

  /// Inicializa notificaciones locales + canal con sonido personalizado
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings);

    // Crear canal
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmaChannel);
  }

  /// Mostrar la notificación manualmente si lo necesitás
  static Future<void> showNotification(String title, String body) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alarma_puerta_v2',
      'Alerta de Puerta',
      channelDescription: 'Alerta crítica con sonido fuerte',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarma'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
