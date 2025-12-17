// lib/core/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Excepción simple para errores de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP básico (singleton) para hablar con tu backend
class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  /// Token actual del usuario
  String? token;

  /// Base URL del backend
  static const String baseUrl = 'http://192.168.1.12:3000';

  final http.Client _http = http.Client();

  Uri _buildUri(String path) {
    return Uri.parse('$baseUrl$path');
  }

  // ===========================
  // GET
  // ===========================
  Future<dynamic> get(
    String path, {
    String? overrideToken,
  }) async {
    final uri = _buildUri(path);

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    final tk = overrideToken ?? token;
    if (tk != null) {
      headers['Authorization'] = 'Bearer $tk';
    }

    final resp = await _http.get(uri, headers: headers);
    return _handleResponse(resp);
  }

  // ===========================
  // POST
  // ===========================
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? data,
    String? overrideToken,
  }) async {
    final uri = _buildUri(path);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final tk = overrideToken ?? token;
    if (tk != null) {
      headers['Authorization'] = 'Bearer $tk';
    }

    final resp = await _http.post(
      uri,
      headers: headers,
      body: data != null ? jsonEncode(data) : null,
    );

    return _handleResponse(resp);
  }

  // ===========================
  // PUT
  // ===========================
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? data,
    String? overrideToken,
  }) async {
    final uri = _buildUri(path);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final tk = overrideToken ?? token;
    if (tk != null) {
      headers['Authorization'] = 'Bearer $tk';
    }

    final resp = await _http.put(
      uri,
      headers: headers,
      body: data != null ? jsonEncode(data) : null,
    );

    return _handleResponse(resp);
  }

  // ===========================
  // DELETE
  // ===========================
  Future<dynamic> delete(
    String path, {
    String? overrideToken,
  }) async {
    final uri = _buildUri(path);

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    final tk = overrideToken ?? token;
    if (tk != null) {
      headers['Authorization'] = 'Bearer $tk';
    }

    final resp = await _http.delete(uri, headers: headers);
    return _handleResponse(resp);
  }

  // ===========================
  // HANDLER
  // ===========================
  dynamic _handleResponse(http.Response resp) {
    if (resp.body.isEmpty) {
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return null;
      }
      throw ApiException('Error HTTP ${resp.statusCode}',
          statusCode: resp.statusCode);
    }

    final decoded = jsonDecode(resp.body);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return decoded;
    }

    String message = 'Error HTTP ${resp.statusCode}';
    if (decoded is Map<String, dynamic>) {
      message = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          message;
    }

    throw ApiException(message, statusCode: resp.statusCode);
  }
}
