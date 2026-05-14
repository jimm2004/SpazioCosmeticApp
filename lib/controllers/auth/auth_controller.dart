import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  // =========================================================
  // LOGIN
  // Funciona para:
  // - cliente
  // - administrador
  // - despacho / bodega
  // - administracion_contable
  // =========================================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final correo = email.trim();
    final clave = password.trim();

    if (correo.isEmpty || clave.isEmpty) {
      throw Exception('Por favor, ingresa correo y contraseña.');
    }

    final response = await _authService.login(
      email: correo,
      password: clave,
    );

    debugPrint('AUTH RESPONSE LOGIN: $response');

    final user = _extraerUsuario(response);
    final token = _extraerToken(response);
    final tipoUsuario = _extraerTipoUsuario(response, user);
    final role = _extraerRol(response, user, tipoUsuario);

    if (token.isEmpty) {
      throw Exception(
        'Login correcto, pero el servidor no devolvió token de sesión.',
      );
    }

    final nombre = user['name']?.toString() ??
        user['nombre']?.toString() ??
        user['nombres']?.toString() ??
        'Usuario';

    return {
      'id': user['id'],
      'name': nombre,
      'email': user['email']?.toString() ??
          user['correo']?.toString() ??
          correo,
      'role': role,
      'rol': role,
      'role_normalizado': _normalizarRol(role),
      'activo': user['activo'] ?? true,
      'tipo_usuario': tipoUsuario,
      'token': token,
      'message': response['message']?.toString() ?? '',
      'raw_user': user,
    };
  }

  // =========================================================
  // REGISTRO PÚBLICO DE CLIENTES
  // =========================================================
  Future<String> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    final nombre = name.trim();
    final correo = email.trim();
    final clave = password.trim();
    final confirmarClave = confirmPassword.trim();

    if (nombre.isEmpty) {
      throw Exception('Por favor, ingresa tu nombre.');
    }

    if (correo.isEmpty) {
      throw Exception('Por favor, ingresa tu correo.');
    }

    if (!_emailValido(correo)) {
      throw Exception('Por favor, ingresa un correo válido.');
    }

    if (clave.isEmpty || confirmarClave.isEmpty) {
      throw Exception('Por favor, completa las contraseñas.');
    }

    if (clave.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    if (clave != confirmarClave) {
      throw Exception('Las contraseñas no coinciden.');
    }

    final response = await _authService.register(
      name: nombre,
      email: correo,
      password: clave,
      passwordConfirmation: confirmarClave,
    );

    try {
      await sendWelcomeEmail(
        correo,
        nombre,
        role: 'cliente',
      );
    } catch (e) {
      debugPrint('Registro correcto, pero falló el correo: $e');
    }

    return response['message']?.toString() ??
        'Registro exitoso. ¡Bienvenido a SpazioStore!';
  }

  // =========================================================
  // ENVIAR CORREO DE BIENVENIDA
  // =========================================================
  Future<void> sendWelcomeEmail(
    String email,
    String name, {
    String role = 'cliente',
  }) async {
    final correo = email.trim();
    final nombre = name.trim();

    if (correo.isEmpty || nombre.isEmpty) {
      throw Exception('Correo y nombre son obligatorios.');
    }

    await _authService.sendWelcomeEmail(
      email: correo,
      name: nombre,
      role: role,
    );

    debugPrint('Correo de bienvenida enviado a $correo');
  }

  // =========================================================
  // RECUPERAR CONTRASEÑA
  // tipoUsuario puede ser:
  // - cliente
  // - personal_administrativo
  // =========================================================
  Future<String> forgotPassword(
    String email, {
    String? tipoUsuario,
  }) async {
    final correo = email.trim();

    if (correo.isEmpty) {
      throw Exception('Por favor, ingresa tu correo electrónico.');
    }

    if (!_emailValido(correo)) {
      throw Exception('Por favor, ingresa un correo válido.');
    }

    final response = await _authService.forgotPassword(
      email: correo,
      tipoUsuario: tipoUsuario,
    );

    return response['message']?.toString() ?? 'Correo enviado con éxito.';
  }

  // =========================================================
  // RESETEAR CONTRASEÑA
  // =========================================================
  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
    String? tipoUsuario,
  }) async {
    final correo = email.trim();
    final codigo = token.trim();
    final clave = password.trim();
    final confirmarClave = passwordConfirmation.trim();

    if (correo.isEmpty || codigo.isEmpty) {
      throw Exception('Correo y token son obligatorios.');
    }

    if (!_emailValido(correo)) {
      throw Exception('Por favor, ingresa un correo válido.');
    }

    if (clave.isEmpty || confirmarClave.isEmpty) {
      throw Exception('Por favor, completa las contraseñas.');
    }

    if (clave.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    if (clave != confirmarClave) {
      throw Exception('Las contraseñas no coinciden.');
    }

    final response = await _authService.resetPassword(
      email: correo,
      token: codigo,
      password: clave,
      passwordConfirmation: confirmarClave,
      tipoUsuario: tipoUsuario,
    );

    return response['message']?.toString() ??
        'Contraseña actualizada correctamente.';
  }

  // =========================================================
  // USUARIO ACTUAL
  // =========================================================
  Future<Map<String, dynamic>> me() async {
    final response = await _authService.getMe();

    debugPrint('AUTH RESPONSE ME: $response');

    final user = _extraerUsuario(response);
    final tipoUsuario = _extraerTipoUsuario(response, user);
    final role = _extraerRol(response, user, tipoUsuario);

    final nombre = user['name']?.toString() ??
        user['nombre']?.toString() ??
        user['nombres']?.toString() ??
        'Usuario';

    return {
      'id': user['id'],
      'name': nombre,
      'email': user['email']?.toString() ??
          user['correo']?.toString() ??
          '',
      'role': role,
      'rol': role,
      'role_normalizado': _normalizarRol(role),
      'activo': user['activo'] ?? true,
      'tipo_usuario': tipoUsuario,
      'raw_user': user,
    };
  }

  // =========================================================
  // LOGOUT
  // =========================================================
  Future<void> logout() async {
    await _authService.logout();
  }

  // =========================================================
  // HELPERS PRIVADOS
  // =========================================================

  Map<String, dynamic> _extraerUsuario(Map<String, dynamic> response) {
    final data = response['data'];

    final rawUser = response['user'] ??
        response['usuario'] ??
        response['personal'] ??
        response['admin'] ??
        response['cliente'] ??
        (data is Map ? data['user'] : null) ??
        (data is Map ? data['usuario'] : null) ??
        (data is Map ? data['personal'] : null) ??
        (data is Map ? data['admin'] : null) ??
        (data is Map ? data['cliente'] : null);

    if (rawUser is Map) {
      return Map<String, dynamic>.from(rawUser);
    }

    return <String, dynamic>{};
  }

  String _extraerToken(Map<String, dynamic> response) {
    final data = response['data'];

    return response['token']?.toString() ??
        response['access_token']?.toString() ??
        response['plainTextToken']?.toString() ??
        response['plain_text_token']?.toString() ??
        (data is Map ? data['token']?.toString() : null) ??
        (data is Map ? data['access_token']?.toString() : null) ??
        (data is Map ? data['plainTextToken']?.toString() : null) ??
        (data is Map ? data['plain_text_token']?.toString() : null) ??
        '';
  }

  String _extraerTipoUsuario(
    Map<String, dynamic> response,
    Map<String, dynamic> user,
  ) {
    final data = response['data'];

    return response['tipo_usuario']?.toString() ??
        response['tipoUsuario']?.toString() ??
        user['tipo_usuario']?.toString() ??
        user['tipoUsuario']?.toString() ??
        (data is Map ? data['tipo_usuario']?.toString() : null) ??
        (data is Map ? data['tipoUsuario']?.toString() : null) ??
        'cliente';
  }

  String _extraerRol(
    Map<String, dynamic> response,
    Map<String, dynamic> user,
    String tipoUsuario,
  ) {
    final data = response['data'];

    final rol = user['role']?.toString() ??
        user['rol']?.toString() ??
        user['cargo']?.toString() ??
        response['role']?.toString() ??
        response['rol']?.toString() ??
        response['cargo']?.toString() ??
        (data is Map ? data['role']?.toString() : null) ??
        (data is Map ? data['rol']?.toString() : null) ??
        (data is Map ? data['cargo']?.toString() : null);

    if (rol != null && rol.trim().isNotEmpty) {
      return _normalizarRol(rol);
    }

    final tipoNormalizado = _normalizarRol(tipoUsuario);

    if (tipoNormalizado == 'cliente') {
      return 'cliente';
    }

    if (tipoNormalizado == 'administracion_contable') {
      return 'administracion_contable';
    }

    if (tipoNormalizado == 'despacho') {
      return 'despacho';
    }

    if (tipoNormalizado == 'administrador' || tipoNormalizado == 'admin') {
      return 'administrador';
    }

    return tipoNormalizado == 'personal_administrativo'
        ? 'administrador'
        : 'cliente';
  }

  String _normalizarRol(String role) {
    return role
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  bool _emailValido(String email) {
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}