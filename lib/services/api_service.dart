import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl =
      'https://lavenderblush-crocodile-665497.hostingersite.com';

  static const Duration requestTimeout = Duration(seconds: 35);
  static const int maxUploadBytes = 8 * 1024 * 1024; // 8 MB

  static const String _tokenKey = 'store_mood_auth_token';
  static const String _tokenSavedAtKey = 'store_mood_auth_token_saved_at';

  String? token;
  bool _initialized = false;
  Future<void>? _initFuture;

  /// Cargar token persistido.
  ///
  /// Recomendado en main.dart antes de runApp:
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ApiService().init();
  Future<void> init() {
    _initFuture ??= _loadTokenFromStorage();
    return _initFuture!;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_tokenKey)?.trim();

      token = storedToken != null && storedToken.isNotEmpty ? storedToken : null;
      _initialized = true;

      if (kDebugMode) {
        debugPrint('TOKEN CARGADO: ${token != null && token!.isNotEmpty}');
      }
    } catch (e) {
      _initialized = true;
      if (kDebugMode) {
        debugPrint('NO SE PUDO CARGAR TOKEN: $e');
      }
    }
  }

  /// Guarda el token en memoria y en almacenamiento local.
  ///
  /// En Flutter Web queda guardado en el origen actual:
  /// - http://localhost:PUERTO
  /// - http://IP_DE_TU_PC:PUERTO
  /// son sesiones separadas para el navegador.
  Future<void> setToken(String? newToken) async {
    token = newToken?.trim();
    if (token != null && token!.isEmpty) token = null;

    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      if (token != null && token!.isNotEmpty) {
        await prefs.setString(_tokenKey, token!);
        await prefs.setString(_tokenSavedAtKey, DateTime.now().toIso8601String());
      } else {
        await prefs.remove(_tokenKey);
        await prefs.remove(_tokenSavedAtKey);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NO SE PUDO GUARDAR TOKEN: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('TOKEN GUARDADO: ${token != null && token!.isNotEmpty}');
    }
  }

  Future<void> clearToken() async {
    token = null;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenSavedAtKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NO SE PUDO LIMPIAR TOKEN: $e');
      }
    }
  }

  Future<bool> hasSavedSession() async {
    await _ensureInitialized();
    return token != null && token!.isNotEmpty;
  }

  Future<String?> getSavedToken() async {
    await _ensureInitialized();
    return token;
  }

  Uri uri(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$cleanPath');
  }

  Map<String, String> get headers {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };

    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    return h;
  }

  Map<String, String> get multipartHeaders {
    final h = <String, String>{
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };

    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    return h;
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _sendJsonRequest(method: 'GET', path: path);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJsonRequest(method: 'POST', path: path, body: body ?? {});
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJsonRequest(method: 'PUT', path: path, body: body ?? {});
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJsonRequest(method: 'PATCH', path: path, body: body ?? {});
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendJsonRequest(method: 'DELETE', path: path, body: body);
  }

  Future<Map<String, dynamic>> _sendJsonRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    await _ensureInitialized();

    try {
      final target = uri(path);
      final encodedBody = body == null ? null : jsonEncode(body);

      late final http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(target, headers: headers).timeout(requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(target, headers: headers, body: encodedBody)
              .timeout(requestTimeout);
          break;
        case 'PUT':
          response = await http
              .put(target, headers: headers, body: encodedBody)
              .timeout(requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(target, headers: headers, body: encodedBody)
              .timeout(requestTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(target, headers: headers, body: encodedBody)
              .timeout(requestTimeout);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      return handleResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verificá tu conexión o intentá nuevamente.',
      );
    } on http.ClientException catch (e) {
      throw Exception(_friendlyNetworkError(e.message));
    } on FormatException {
      throw Exception('Respuesta inválida del servidor.');
    } catch (e) {
      final text = e.toString().replaceFirst('Exception: ', '');
      throw Exception(text.isEmpty ? 'Error de conexión con el servidor.' : text);
    }
  }

  /// Método principal para subir imágenes compatible con Web, Android, iOS y PC.
  ///
  /// - No usa dart:io.
  /// - No usa MultipartFile.fromPath.
  /// - En Flutter Web sube bytes con XFile.readAsBytes().
  /// - No agregues Content-Type manual para multipart; http genera el boundary.
  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required String fileField,
    required XFile file,
    Map<String, String>? fields,
  }) async {
    return multipartPostXFile(
      path,
      fileField: fileField,
      file: file,
      fields: fields,
    );
  }

  Future<Map<String, dynamic>> multipartPostXFile(
    String path, {
    required String fileField,
    required XFile file,
    Map<String, String>? fields,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('La imagen seleccionada está vacía.');
      }

      if (bytes.length > maxUploadBytes) {
        throw Exception(
          'La imagen supera ${(maxUploadBytes / (1024 * 1024)).round()} MB. Comprimila o seleccioná otra.',
        );
      }

      return multipartPostBytes(
        path,
        fileField: fileField,
        bytes: bytes,
        filename: _safeFileName(file.name, fallbackPath: file.path),
        mimeType: file.mimeType,
        fields: fields,
      );
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado al subir la imagen. Intentá nuevamente.',
      );
    } catch (e) {
      final text = e.toString().replaceFirst('Exception: ', '');
      throw Exception(text.isEmpty ? 'No se pudo leer la imagen.' : text);
    }
  }

  Future<Map<String, dynamic>> multipartPostBytes(
    String path, {
    required String fileField,
    required Uint8List bytes,
    required String filename,
    String? mimeType,
    Map<String, String>? fields,
  }) async {
    await _ensureInitialized();

    try {
      if (bytes.isEmpty) {
        throw Exception('La imagen seleccionada está vacía.');
      }

      if (bytes.length > maxUploadBytes) {
        throw Exception(
          'La imagen supera ${(maxUploadBytes / (1024 * 1024)).round()} MB. Comprimila o seleccioná otra.',
        );
      }

      final cleanMimeType =
          mimeType ?? lookupMimeType(filename, headerBytes: bytes) ?? 'image/jpeg';
      final parts = cleanMimeType.split('/');
      final type = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : 'image';
      final subtype = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'jpeg';

      final request = http.MultipartRequest('POST', uri(path));
      request.headers.addAll(multipartHeaders);

      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(fields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: filename,
          contentType: MediaType(type, subtype),
        ),
      );

      final streamed = await request.send().timeout(requestTimeout);
      final response = await http.Response.fromStream(streamed).timeout(requestTimeout);

      return handleResponse(response);
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado al subir la imagen. Intentá nuevamente.',
      );
    } on http.ClientException catch (e) {
      throw Exception(_friendlyNetworkError(e.message));
    } catch (e) {
      final text = e.toString().replaceFirst('Exception: ', '');
      throw Exception(text.isEmpty ? 'No se pudo subir la imagen.' : text);
    }
  }

  Map<String, dynamic> handleResponse(http.Response response) {
    final data = decode(response);

    if (kDebugMode) {
      debugPrint('API STATUS ${response.statusCode}: ${_shortLog(response.body)}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = _extractErrorMessage(data);

    if (response.statusCode == 0) {
      message = 'No se pudo conectar con el servidor.';
    } else if (response.statusCode == 401) {
      message = 'No autenticado. Validá la sesión desde la pantalla inicial.';
      // No se limpia automáticamente aquí. En web móvil una recarga o una
      // carrera de inicialización puede provocar un 401 puntual; AppSessionGate
      // decide cuándo eliminar el token después de validar /api/me.
    } else if (response.statusCode == 403) {
      message = 'No tenés permisos para realizar esta acción.';
    } else if (response.statusCode == 404) {
      message = data['message']?.toString() ?? 'Ruta no encontrada en la API.';
    } else if (response.statusCode == 413) {
      message = 'El archivo es demasiado grande para el servidor.';
    } else if (response.statusCode == 419) {
      message = 'La sesión expiró. Validá la sesión desde la pantalla inicial.';
      // AppSessionGate limpia el token solo cuando confirma expiración real.
    } else if (response.statusCode == 422) {
      message = _extractValidationError(data);
    } else if (response.statusCode >= 500) {
      message = data['message']?.toString() ??
          'Error interno del servidor. Revisá logs del backend.';
    }

    throw Exception(message);
  }

  Map<String, dynamic> decode(http.Response response) {
    try {
      final raw = response.body.trim();

      if (raw.isEmpty) {
        return {'message': 'Respuesta vacía del servidor'};
      }

      final body = jsonDecode(raw);

      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      if (body is List) return {'data': body};

      return {'data': body};
    } catch (_) {
      return {
        'message': response.body.isEmpty
            ? 'Respuesta vacía del servidor'
            : 'Respuesta inválida del servidor',
        'raw': response.body,
      };
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final validation = _extractValidationError(data);
    if (validation.trim().isNotEmpty && validation != 'Error del servidor') {
      return validation;
    }

    return data['message']?.toString() ??
        data['error']?.toString() ??
        data['raw']?.toString() ??
        'Error del servidor';
  }

  String _extractValidationError(Map<String, dynamic> data) {
    if (data['errors'] is Map) {
      final errors = Map<String, dynamic>.from(data['errors'] as Map);

      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return data['message']?.toString() ??
        data['error']?.toString() ??
        'Error del servidor';
  }

  String _friendlyNetworkError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('xmlhttprequest') ||
        lower.contains('cors') ||
        lower.contains('failed to fetch')) {
      return 'El navegador bloqueó la solicitud por CORS. Revisá los headers del backend.';
    }

    if (lower.contains('connection') || lower.contains('socket')) {
      return 'No se pudo conectar con el servidor. Revisá conexión o dominio API.';
    }

    return message.isEmpty ? 'Error de red.' : message;
  }

  String _safeFileName(String? name, {String? fallbackPath}) {
    String value = (name ?? '').trim();

    if (value.isEmpty && fallbackPath != null) {
      final cleanPath = fallbackPath.replaceAll('\\', '/');
      final parts = cleanPath.split('/').where((e) => e.trim().isNotEmpty);
      value = parts.isEmpty ? '' : parts.last;
    }

    if (value.isEmpty) {
      value = 'imagen_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }

    value = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (!value.contains('.')) {
      value = '$value.jpg';
    }

    return value;
  }

  String _shortLog(String value) {
    const max = 900;
    final clean = value.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}...';
  }
}
