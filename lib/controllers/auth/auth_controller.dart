import 'package:flutter/foundation.dart';

import '../../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  // =========================================================
  // LOGIN
  // Funciona para:
  // - cliente
  // - personal_administrativo: administrador / despacho
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

    final user = response['user'] ?? {};

    return {
      'id': user['id'],
      'name': user['name']?.toString() ?? 'Usuario',
      'email': user['email']?.toString() ?? '',
      'role': user['role']?.toString() ?? 'cliente',
      'activo': user['activo'] ?? true,
      'tipo_usuario': response['tipo_usuario']?.toString() ??
          user['tipo_usuario']?.toString() ??
          'cliente',
      'token': response['token']?.toString() ?? '',
      'message': response['message']?.toString() ?? '',
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

    // El registro ya quedó guardado en Laravel.
    // El correo se intenta enviar, pero si falla no bloquea el registro.
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

    final user = response['user'] ?? {};

    return {
      'id': user['id'],
      'name': user['name']?.toString() ?? 'Usuario',
      'email': user['email']?.toString() ?? '',
      'role': user['role']?.toString() ?? 'cliente',
      'activo': user['activo'] ?? true,
      'tipo_usuario': response['tipo_usuario']?.toString() ??
          user['tipo_usuario']?.toString() ??
          'cliente',
    };
  }

  // =========================================================
  // LOGOUT
  // =========================================================
  Future<void> logout() async {
    await _authService.logout();
  }

  // =========================================================
  // VALIDACIÓN PRIVADA
  // =========================================================
  bool _emailValido(String email) {
    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}