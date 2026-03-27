import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class AuthController {
  final ApiService _apiService = ApiService();

  Future<void> sendWelcomeEmail(
    String email,
    String name, {
    String role = 'cliente',
  }) async {
    try {
      final url = Uri.parse(
        'https://lavenderblush-crocodile-665497.hostingersite.com/api/send-welcome-email',
      );

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'email': email,
          'name': name,
          'role': role,
        }),
      );

      if (response.statusCode != 200) {
        // Decodificación segura: previene colapsos si Laravel devuelve un error HTML en lugar de JSON
        String errorMessage = 'Error desconocido en el servidor de correos';
        try {
          final decodedResponse = jsonDecode(response.body);
          errorMessage = decodedResponse['message'] ?? errorMessage;
        } catch (_) {
          // Si no es JSON, capturamos un pedazo del texto (ej. HTML de error 500)
          errorMessage = response.body.length > 100 
              ? '${response.body.substring(0, 100)}...' 
              : response.body;
        }
        throw Exception('Fallo al enviar correo (${response.statusCode}): $errorMessage');
      } else {
        // Todo salió bien
        debugPrint('Correo de bienvenida enviado con éxito a $email');
      }
    } catch (e) {
      // Elevamos la excepción para que el Catch en UI pueda mostrarla
      throw Exception('Excepción al enviar correo: $e');
    }
  }

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Por favor, ingresa correo y contraseña.');
    }

    final response = await _apiService.login(
      email: email.trim(),
      password: password.trim(),
    );

    return {
      'name': response['user']?['name']?.toString() ?? 'Usuario',
      'email': response['user']?['email']?.toString() ?? '',
      'role': response['user']?['role']?.toString() ?? 'cliente',
      'token': response['token']?.toString() ?? '',
      'message': response['message']?.toString() ?? '',
    };
  }

  // REGISTRO (Clientes)
  Future<String> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (name.trim().isEmpty) {
      throw Exception('Por favor, ingresa tu nombre.');
    }

    if (email.trim().isEmpty) {
      throw Exception('Por favor, ingresa tu correo.');
    }

    if (password.trim().isEmpty || confirmPassword.trim().isEmpty) {
      throw Exception('Por favor, completa las contraseñas.');
    }

    if (password != confirmPassword) {
      throw Exception('Las contraseñas no coinciden.');
    }

    final response = await _apiService.register(
      name: name.trim(),
      email: email.trim(),
      password: password.trim(),
      passwordConfirmation: confirmPassword.trim(),
    );

    // Intentamos enviar el correo, pero si falla no bloqueamos el éxito del registro.
    // Porque la cuenta YA se guardó en la base de datos de Laravel.
    try {
      await sendWelcomeEmail(
        email.trim(),
        name.trim(),
        role: 'cliente',
      );
    } catch (e) {
      debugPrint('El registro fue exitoso en BD, pero el correo falló: $e');
    }

    return response['message']?.toString() ??
        'Registro exitoso. ¡Bienvenido a SpazioStore!';
  }

  // RECUPERAR CONTRASEÑA
  Future<String> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      throw Exception('Por favor, ingresa tu correo electrónico.');
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw Exception('Por favor, ingresa un correo válido.');
    }

    final response = await _apiService.forgotPassword(
      email: email.trim(),
    );

    return response['message']?.toString() ?? 'Correo enviado con éxito.';
  }

  // LOGOUT
  Future<void> logout() async {
    await _apiService.logout();
  }
}
