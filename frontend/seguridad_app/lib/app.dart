import 'package:flutter/material.dart';
import 'core/storage/session_manager.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/forgot_password_page.dart';
import 'features/cliente/pages/dashboard_cliente.dart';
import 'features/admin/pages/dashboard_admin.dart';
import 'features/guardia/pages/dashboard_guardia.dart';

class AppRoutes {
  static String get initialRoute {
    final token = SessionManager.getToken();
    if (token == null) return "/login";

    final rol = SessionManager.getRoleFromToken(token);

    if (rol == "CLIENTE") return "/cliente";
    if (rol == "GUARDIA") return "/guardia";
    if (rol == "ADMIN") return "/admin";

    return "/login";
  }

  static final routes = <String, WidgetBuilder>{
    "/login": (_) => const LoginPage(),
    "/forgot": (_) => const ForgotPasswordPage(),
    "/cliente": (_) => const DashboardCliente(),
    "/admin": (_) => const DashboardAdmin(),
    "/guardia": (_) => const DashboardGuardia(),
  };
}
