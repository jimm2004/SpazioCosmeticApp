import 'dart:convert';
import 'dart:io';

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
  }

  void clearToken() {
    token = null;
  }

  Map<String, String> get headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, String> get authMultipartHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri uri(String path) {
    return Uri.parse('$baseUrl$path');
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

  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required String fileField,
    required File file,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      uri(path),
    );

    request.headers.addAll(authMultipartHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final mimeTypeData = lookupMimeType(file.path)?.split('/') ??
        ['image', 'jpeg'];

    request.files.add(
      await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return handleResponse(response);
  }

  Map<String, dynamic> handleResponse(http.Response response) {
    final data = decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] ??
        data['error'] ??
        'Error del servidor';

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
    } catch (e) {
      return {
        'message': 'Respuesta inválida del servidor',
        'raw': response.body,
      };
    }
  }
}