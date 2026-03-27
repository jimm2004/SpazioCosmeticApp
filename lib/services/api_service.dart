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

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, String> get _authHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      token = data['token']?.toString();
      return data;
    }

    throw Exception(data['message'] ?? 'Error en login');
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final data = _decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Error en registro');
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/forgot-password'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
      }),
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Error al solicitar recuperación');
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/me'),
      headers: _headers,
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'Error obteniendo usuario');
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/logout'),
      headers: _headers,
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      token = null;
      return data;
    }

    throw Exception(data['message'] ?? 'Error al cerrar sesión');
  }

  // =========================================================
  // PRODUCTOS ADMIN
  // =========================================================

  Future<List<dynamic>> obtenerProductosAdmin() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/productos'),
      headers: _headers,
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      return data['data'] ?? [];
    }

    throw Exception(data['message'] ?? 'Error al obtener productos');
  }

  Future<Map<String, dynamic>> obtenerDetalleProducto(int idProducto) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/productos/$idProducto'),
      headers: _headers,
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      return data['data'] ?? {};
    }

    throw Exception(
      data['message'] ?? 'Error al obtener detalle del producto',
    );
  }

  Future<String> subirImagenProducto({
    required int idProducto,
    required File imagen,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/admin/productos/$idProducto/imagen'),
    );

    request.headers.addAll(_authHeaders);

    final mimeTypeData =
        lookupMimeType(imagen.path)?.split('/') ?? ['image', 'jpeg'];

    request.files.add(
      await http.MultipartFile.fromPath(
        'imagen',
        imagen.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response);

    if (response.statusCode == 200) {
      return data['message']?.toString() ?? 'Imagen subida correctamente';
    }

    throw Exception(data['message'] ?? 'Error al subir imagen');
  }

  // NUEVO MÉTODO: Ocultar o mostrar producto
  Future<String> cambiarEstadoProducto({
    required int idProducto,
    required bool activo,
  }) async {
    final response = await http.post(
      // Usamos el mismo prefijo /api/admin/productos/...
      Uri.parse('$baseUrl/api/admin/productos/$idProducto/visibilidad'),
      headers: _headers,
      body: jsonEncode({
        'activo': activo, // Flutter convierte el booleano a JSON automáticamente
      }),
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      // Si el servidor nos manda un mensaje personalizado, lo usamos. 
      // Si no, mandamos nuestro propio mensaje de éxito.
      return data['message']?.toString() ?? 
          (activo ? 'Producto visible en el catálogo' : 'Producto oculto exitosamente');
    }

    throw Exception(data['message'] ?? 'Error al cambiar visibilidad');
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      return {'data': body};
    } catch (e) {
      return {
        'message': 'Respuesta inválida del servidor',
        'raw': response.body,
      };
    }
  }
}