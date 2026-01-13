import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/admin_casa.dart';

class AdminCasasApi {
  final ApiClient api;
  AdminCasasApi(this.api);

  static const String _base = '/api/casa';

  Future<List<AdminCasa>> listar() async {
    final resp = await api.get(_base);

    debugPrint("RESP CASAS RAW => $resp");
    debugPrint("TIPO => ${resp.runtimeType}");

    if (resp is! List) return [];
    return resp
        .map((e) => AdminCasa.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<AdminCasa> crear(AdminCasa casa) async {
    final resp = await api.post(_base, data: casa.toCreateJson());
    return AdminCasa.fromJson(Map<String, dynamic>.from(resp));
  }

  Future<AdminCasa> actualizar(int id, AdminCasa casa) async {
    final resp = await api.put('$_base/$id', data: casa.toUpdateJson());
    return AdminCasa.fromJson(Map<String, dynamic>.from(resp));
  }

  Future<void> deshabilitar(int id) async {
    await api.delete('$_base/$id');
  }
}
