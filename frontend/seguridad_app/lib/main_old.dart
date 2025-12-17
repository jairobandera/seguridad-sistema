import 'package:flutter/material.dart';
import 'app.dart';
import 'core/storage/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar sesión (SharedPreferences)
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
