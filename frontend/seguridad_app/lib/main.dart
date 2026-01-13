// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'core/storage/session_manager.dart';
import 'core/notificacion/notification_service.dart';

// ===============================
// Handler para notificaciones en background (SOLO móvil)
// ===============================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificación BACKGROUND: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sesión
  await SessionManager.init();

  //Firebase SOLO en móvil (Android/iOS)
  if (!kIsWeb) {
    await Firebase.initializeApp();

    await NotificationService.initialize();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 Notificación abierta por el usuario");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

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
