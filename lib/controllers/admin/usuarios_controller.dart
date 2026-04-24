import '../../services/usuarios_service.dart';

class UsuariosController {
  final UsuariosService _service = UsuariosService();

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final data = await _service.obtenerUsuarios();

    return data
        .where((e) => e is Map)
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(e as Map),
        )
        .toList();
  }

  Future<String> cambiarEstadoUsuario({
    required int id,
    required bool activo,
    required String tipoUsuario,
  }) async {
    if (id <= 0) {
      throw Exception('ID de usuario inválido.');
    }

    if (tipoUsuario.trim().isEmpty) {
      throw Exception('Tipo de usuario inválido.');
    }

    return await _service.cambiarEstadoUsuario(
      id: id,
      activo: activo,
      tipoUsuario: tipoUsuario,
    );
  }

  Future<String> crearUsuarioAdministrativo({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('El nombre es obligatorio.');
    }

    if (email.trim().isEmpty) {
      throw Exception('El correo es obligatorio.');
    }

    if (password.trim().isEmpty || passwordConfirmation.trim().isEmpty) {
      throw Exception('La contraseña es obligatoria.');
    }

    if (password != passwordConfirmation) {
      throw Exception('Las contraseñas no coinciden.');
    }

    if (role.trim().isEmpty) {
      throw Exception('El rol es obligatorio.');
    }

    final response = await _service.crearUsuario(
      name: name.trim(),
      email: email.trim(),
      password: password.trim(),
      passwordConfirmation: passwordConfirmation.trim(),
      role: role.trim(),
    );

    return response['message']?.toString() ??
        'Usuario creado correctamente.';
  }
}