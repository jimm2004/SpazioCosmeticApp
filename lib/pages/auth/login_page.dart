import 'package:flutter/material.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../models/mail/forgot_password_dialog.dart';
import '../../services/api_service.dart';
import '../admin/administrador_page.dart';
import '../admin/contabilidad/administracion_contable_page.dart';
import '../catalogo/catalogo_page.dart';
import 'widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  bool loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showCustomDialog(
        context,
        title: 'Campos Vacíos',
        message: 'Por favor, completa ambos campos',
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await _authController.login(email, password);

      debugPrint('LOGIN RESULT: $result');

      final String token = (result['token'] ??
              result['access_token'] ??
              result['plainTextToken'] ??
              result['plain_text_token'] ??
              '')
          .toString();

      if (token.isEmpty) {
        throw Exception(
          'Login correcto, pero el servidor no devolvió token de sesión.',
        );
      }

      ApiService().setToken(token);

      final String userName =
          result['name']?.toString().trim().isNotEmpty == true
              ? result['name'].toString()
              : 'Usuario';

      final String role = (result['role'] ??
              result['rol'] ??
              result['tipo_usuario'] ??
              'cliente')
          .toString();

      final String rolNormalizado = _normalizarRol(role);

      debugPrint(
        'TOKEN SETEADO: ${ApiService().token != null && ApiService().token!.isNotEmpty}',
      );
      debugPrint('ROL ORIGINAL: $role');
      debugPrint('ROL NORMALIZADO: $rolNormalizado');

      if (!mounted) return;

      if (_esContabilidad(rolNormalizado)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdministracionContablePage(
              adminName: userName,
              rol: rolNormalizado,
            ),
          ),
        );
        return;
      }

      if (_esAdministradorOBodega(rolNormalizado)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdministradorPage(
              adminName: userName,
              rol: rolNormalizado,
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogoPage(userName: userName),
        ),
      );
    } catch (e) {
      debugPrint('ERROR LOGIN REAL: $e');

      if (mounted) {
        showCustomDialog(
          context,
          title: 'Error de Login',
          message: e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

  bool _esContabilidad(String rol) {
    return rol == 'administracion_contable' ||
        rol == 'contabilidad' ||
        rol == 'admin_contable' ||
        rol == 'administrativo_contable';
  }

  bool _esAdministradorOBodega(String rol) {
    return rol == 'administrador' ||
        rol == 'admin' ||
        rol == 'despacho' ||
        rol == 'bodega' ||
        rol == 'supervisor_bodega';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Text(
                '¡Hola de nuevo!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Ingresa tus credenciales para continuar.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: buildInputDecoration('Correo electrónico'),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!loading) _login();
                },
                decoration: buildInputDecoration(
                  'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () => showForgotPasswordDialog(
                            context,
                            _authController,
                          ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'INICIAR SESIÓN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}