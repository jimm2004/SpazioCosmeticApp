import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String deviceName = 'flutter-app',
  }) async {
    final data = await _api.post(
      '/api/login',
      body: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );

    final token = data['token']?.toString();

    if (token != null && token.isNotEmpty) {
      _api.setToken(token);
    }

    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String deviceName = 'flutter-app',
  }) async {
    final data = await _api.post(
      '/api/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      },
    );

    final token = data['token']?.toString();

    if (token != null && token.isNotEmpty) {
      _api.setToken(token);
    }

    return data;
  }

  Future<Map<String, dynamic>> sendWelcomeEmail({
    required String email,
    required String name,
    String role = 'cliente',
  }) async {
    return await _api.post(
      '/api/send-welcome-email',
      body: {
        'email': email,
        'name': name,
        'role': role,
      },
    );
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    String? tipoUsuario,
  }) async {
    return await _api.post(
      '/api/forgot-password',
      body: {
        'email': email,
        if (tipoUsuario != null) 'tipo_usuario': tipoUsuario,
      },
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
    String? tipoUsuario,
  }) async {
    return await _api.post(
      '/api/reset-password',
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (tipoUsuario != null) 'tipo_usuario': tipoUsuario,
      },
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    return await _api.get('/api/me');
  }

  Future<Map<String, dynamic>> logout() async {
    final data = await _api.post('/api/logout');
    _api.clearToken();
    return data;
  }
}