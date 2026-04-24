import 'api_service.dart';

class UsuariosService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> obtenerUsuarios() async {
    final data = await _api.get('/api/admin/usuarios');
    return data['users'] ?? [];
  }

  Future<List<dynamic>> obtenerClientes() async {
    final data = await _api.get('/api/admin/usuarios');
    return data['clientes'] ?? [];
  }

  Future<List<dynamic>> obtenerPersonalAdministrativo() async {
    final data = await _api.get('/api/admin/usuarios');
    return data['personal_administrativo'] ?? [];
  }

  Future<Map<String, dynamic>> crearUsuario({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    return await _api.post(
      '/api/admin/usuarios',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      },
    );
  }

  // Alias por compatibilidad con pantallas viejas
  Future<Map<String, dynamic>> crearUsuarioAdministrativo({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    return await crearUsuario(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: role,
    );
  }

  Future<String> cambiarEstadoUsuario({
    required int id,
    required bool activo,
    required String tipoUsuario,
  }) async {
    final data = await _api.post(
      '/api/admin/usuarios/$id/estado',
      body: {
        'activo': activo,
        'tipo_usuario': tipoUsuario,
      },
    );

    return data['message']?.toString() ??
        'Estado actualizado correctamente';
  }
}