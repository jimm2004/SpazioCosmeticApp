import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/platform/mood_platform.dart';

typedef TokenProvider = Future<String?> Function();

class MoodApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  MoodApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'MoodApiException($statusCode): $message';
}

class MoodApiClient {
  final String baseUrl;
  final TokenProvider? tokenProvider;
  final http.Client _client;

  MoodApiClient({
    String? baseUrl,
    this.tokenProvider,
    http.Client? client,
  })  : baseUrl = _normalizeBaseUrl(
          baseUrl ?? MoodPlatformConfig.apiBaseUrl(),
        ),
        _client = client ?? http.Client();

  static String _normalizeBaseUrl(String value) {
    final clean = value.trim();
    if (clean.endsWith('/')) {
      return clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  Future<Map<String, String>> _headers() async {
    final token = await tokenProvider?.call();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Uri _uri(String path, {Map<String, dynamic>? query}) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$cleanPath');

    if (query == null || query.isEmpty) {
      return uri;
    }

    final cleanQuery = <String, String>{};

    query.forEach((key, value) {
      if (value == null) return;

      final text = value.toString().trim();
      if (text.isEmpty) return;

      cleanQuery[key] = text;
    });

    return uri.replace(
      queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get(
      _uri(path, query: query),
      headers: await _headers(),
    );

    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.post(
      _uri(path, query: query),
      headers: await _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decode(response);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.put(
      _uri(path, query: query),
      headers: await _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _decode(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final request = http.Request(
      'DELETE',
      _uri(path, query: query),
    );

    request.headers.addAll(await _headers());

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic payload;

    try {
      payload = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      payload = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    String message = 'Error de comunicación con el servidor.';
    dynamic errors;

    if (payload is Map<String, dynamic>) {
      message = (payload['message'] ?? message).toString();
      errors = payload['errors'];
    } else if (payload != null) {
      message = payload.toString();
    }

    throw MoodApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }

  void close() {
    _client.close();
  }
}