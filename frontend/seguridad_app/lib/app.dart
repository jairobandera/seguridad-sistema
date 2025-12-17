import 'package:flutter/material.dart';
import 'core/storage/session_manager.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/forgot_password_page.dart';
import 'features/cliente/pages/dashboard_cliente.dart';
import 'features/guardia/pages/dashboard_guardia.dart';
import 'features/admin/pages/dashboard_admin.dart';

class AppRoutes {
  static String get initialRoute {
    final token = SessionManager.getToken();
    final rol = SessionManager.getRole();

    if (token == null) return "/login";

    if (rol == "CLIENTE") return "/cliente";
    if (rol == "GUARDIA") return "/guardia";
    if (rol == "ADMIN") return "/admin";

    return "/login";
  }

  static final routes = <String, WidgetBuilder>{
    "/login": (_) => const LoginPage(),
    "/forgot": (_) => const ForgotPasswordPage(),
    "/cliente": (_) => const DashboardCliente(),
    "/guardia": (_) => const DashboardGuardia(),
    "/admin": (_) => const DashboardAdmin(),
  };
}
