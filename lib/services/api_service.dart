import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  static const String baseUrl =
      'https://lavenderblush-crocodile-665497.hostingersite.com';

  String? token;

  void setToken(String? newToken) {
    token = newToken;
    debugPrint('TOKEN GUARDADO: ${token != null && token!.isNotEmpty}');
  }

  void clearToken() {
    token = null;
  }

  Uri uri(String path) {
    return Uri.parse('$baseUrl$path');
  }

  Map<String, String> get headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    return h;
  }

  Map<String, String> get multipartHeaders {
    final h = <String, String>{
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    return h;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      uri(path),
      headers: headers,
    );

    return handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      uri(path),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.put(
      uri(path),
      headers: headers,
      body: jsonEncode(body ?? {}),
    );

    return handleResponse(response);
  }

  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required String fileField,
    required File file,
    Map<String, String>? fields,
  }) async {
    if (!await file.exists()) {
      throw Exception('La imagen seleccionada no existe en el dispositivo.');
    }

    final request = http.MultipartRequest(
      'POST',
      uri(path),
    );

    request.headers.addAll(multipartHeaders);

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');

    debugPrint('SUBIENDO IMAGEN A: ${uri(path)}');
    debugPrint('MIME: $mimeType');
    debugPrint('TOKEN EN MULTIPART: ${token != null && token!.isNotEmpty}');
    debugPrint('FIELDS: ${fields ?? {}}');

    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('STATUS MULTIPART: ${response.statusCode}');
    debugPrint('BODY MULTIPART: ${response.body}');

    return handleResponse(response);
  }

  Map<String, dynamic> handleResponse(http.Response response) {
    final data = decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = data['message']?.toString() ??
        data['error']?.toString() ??
        'Error del servidor';

    if (data['errors'] is Map) {
      final errors = Map<String, dynamic>.from(data['errors']);

      if (errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          message = firstError.first.toString();
        } else {
          message = firstError.toString();
        }
      }
    }

    if (response.statusCode == 401) {
      message = 'No autenticado. Cerrá sesión e iniciá sesión nuevamente.';
    }

    throw Exception(message);
  }

  Map<String, dynamic> decode(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        return body;
      }

      return {
        'data': body,
      };
    } catch (_) {
      return {
        'message': response.body.isEmpty
            ? 'Respuesta vacía del servidor'
            : 'Respuesta inválida del servidor',
        'raw': response.body,
      };
    }
  }
}