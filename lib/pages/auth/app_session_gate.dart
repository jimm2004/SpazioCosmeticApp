import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/catalogo_service.dart';
import '../admin/administrador_page.dart';
import '../catalogo/catalogo_page.dart';
import 'auth_page.dart';

/// Puerta de sesión para Flutter Web, Android, iOS y escritorio.
///
/// Objetivo:
/// - Si el navegador móvil recarga la app, se restaura la sesión desde
///   SharedPreferences antes de construir la pantalla principal.
/// - No manda al login por una recarga normal.
/// - Solo limpia el token cuando la API confirma que realmente no es válido.
class AppSessionGate extends StatefulWidget {
  const AppSessionGate({super.key});

  @override
  State<AppSessionGate> createState() => _AppSessionGateState();
}

class _AppSessionGateState extends State<AppSessionGate> {
  late Future<Widget> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = _resolveHome();
  }

  Future<Widget> _resolveHome() async {
    await ApiService().init();

    final hasToken = await ApiService().hasSavedSession();
    if (!hasToken) {
      return const AuthHomePage();
    }

    try {
      final perfil = await CatalogoService().obtenerMiPerfil();
      final name = perfil.name.trim().isNotEmpty ? perfil.name.trim() : 'Usuario';
      final role = perfil.role.trim().toLowerCase();

      if (_isAdminRole(role)) {
        return AdministradorPage(adminName: name, rol: role);
      }

      return CatalogoPage(userName: name);
    } catch (e) {
      final text = e.toString().replaceFirst('Exception: ', '').toLowerCase();

      // Solo aquí limpiamos sesión si la API confirma que el token no sirve.
      // Si fue timeout/red móvil/CORS temporal, NO borramos el token.
      if (_isAuthError(text)) {
        await ApiService().clearToken();
        return const AuthHomePage();
      }

      return _SessionRecoveryPage(
        message: e.toString().replaceFirst('Exception: ', ''),
        onRetry: () {
          setState(() {
            _homeFuture = _resolveHome();
          });
        },
      );
    }
  }

  bool _isAdminRole(String role) {
    final clean = role.toLowerCase().trim();
    return clean == 'administrador' ||
        clean == 'admin' ||
        clean == 'despacho' ||
        clean == 'contabilidad' ||
        clean == 'administracion_contable' ||
        clean == 'administración_contable' ||
        clean == 'administracion contable' ||
        clean == 'administración contable';
  }

  bool _isAuthError(String text) {
    return text.contains('no autenticado') ||
        text.contains('unauthenticated') ||
        text.contains('401') ||
        text.contains('419') ||
        text.contains('sesión expiró') ||
        text.contains('sesion expiro') ||
        text.contains('session expired');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }

        return const _SessionLoadingPage();
      },
    );
  }
}

class _SessionLoadingPage extends StatelessWidget {
  const _SessionLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFDF7FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFE91E63)),
            SizedBox(height: 18),
            Text(
              'Restaurando sesión...',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Un momento, estamos levantando la operación.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRecoveryPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SessionRecoveryPage({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEEF6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_tethering_error_rounded,
                        color: Color(0xFFE91E63),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudo validar la sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.isEmpty
                          ? 'La red móvil recargó la página o tardó demasiado. Tu token no fue eliminado.'
                          : message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54, height: 1.35),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        await ApiService().clearToken();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthHomePage()),
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
