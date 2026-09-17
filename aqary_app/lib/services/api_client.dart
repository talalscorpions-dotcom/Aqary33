import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Thrown for any non-2xx response, carrying the backend's own error
/// message (every aqary_backend error body is `{"error": "..."}`) so
/// call sites can show it directly instead of a generic failure string.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Minimal JSON HTTP client for the AQARY backend. Holds the current
/// session's JWT in memory (set by [AuthService]) and attaches it as a
/// Bearer token on every request.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) => _token = token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    Map<String, String>? params;
    if (query != null) {
      params = {
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
      };
      if (params.isEmpty) params = null;
    }
    return Uri.parse('${ApiConfig.baseUrl}$normalized')
        .replace(queryParameters: params);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decode(res);
  }

  /// Like [get], but for endpoints whose body is a bare JSON array (every
  /// `admin.controller.js` list/analytics endpoint returns `result.rows`
  /// directly rather than wrapping it in `{results: [...]}`).
  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      _uri(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      _uri(path),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body = const {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = body['error']?.toString() ??
          'Request failed (HTTP ${res.statusCode}).';
      throw ApiException(res.statusCode, message);
    }
    return body;
  }

  List<dynamic> _decodeList(http.Response res) {
    final dynamic decoded = res.body.isNotEmpty ? jsonDecode(res.body) : const [];
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = (decoded is Map && decoded['error'] != null)
          ? decoded['error'].toString()
          : 'Request failed (HTTP ${res.statusCode}).';
      throw ApiException(res.statusCode, message);
    }
    return decoded is List ? decoded : const [];
  }
}
