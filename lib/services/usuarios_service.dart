import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UsuariosService {
  final ApiService _apiService = ApiService();

  String get _baseUrl => ApiService.baseUrl;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_apiService.token != null && _apiService.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_apiService.token}';
    }

    return headers;
  }

  Future<List<dynamic>> obtenerUsuarios() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/admin/usuarios'),
      headers: _headers,
    );

    final data = _decode(response);

    if (response.statusCode == 200) {
      return data['users'] ?? [];
    }

    throw Exception(data['message'] ?? 'Error al obtener usuarios');
  }

  Future<Map<String, dynamic>> crearUsuarioAdministrativo({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/usuarios'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      }),
    );

    final data = _decode(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Error al crear usuario');
  }

  // =========================================================
  // NUEVO MÉTODO: CAMBIAR ESTADO DEL USUARIO (Activar/Desactivar)
  // =========================================================
  Future<String> cambiarEstadoUsuario(int id, bool activo) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/usuarios/$id/estado'),
      headers: _headers,
      // Se envía el booleano al servidor para cambiar el estatus en BD
      body: jsonEncode({'activo': activo}), 
    );

    final data = _decode(response);
    
    if (response.statusCode == 200) {
      return data['message']?.toString() ?? 'Estado actualizado correctamente';
    }
    
    throw Exception(data['message'] ?? 'Error al cambiar el estado del usuario');
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