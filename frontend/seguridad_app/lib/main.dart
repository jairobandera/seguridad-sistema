import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'core/storage/session_manager.dart';
import 'core/notificacion/notification_service.dart';

// ===============================
// Handler para notificaciones en background
// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificación BACKGROUND: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===============================
  // Inicializar Firebase
  // ===============================
  await Firebase.initializeApp();

  await NotificationService.initialize();

  // Notificaciones recibidas mientras la app está ABIERTA
  /*FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Alerta';

    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    print("📩 Notificación FOREGROUND → $title | $body");

    // ESTA es la que usa tu canal con alarma.mp3
    await NotificationService.showNotification(title, body);
  });*/ //Esto comentado es para que suene aun estando en la app abierta

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 Notificación abierta por el usuario");
  });

  // Registrar handler de notificaciones en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ===============================
  // Inicializar sesión (lo que ya tenías)
  // ===============================
  await SessionManager.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Seguridad App",
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
