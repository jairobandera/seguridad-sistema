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

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(settings);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmaChannel);
  }

  static Future<void> showAlarmaPuerta(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alarma_puerta_v2',
      'Alerta de Puerta',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarma'),
    );

    const details = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
