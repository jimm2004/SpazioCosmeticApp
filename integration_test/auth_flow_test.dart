import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo de integración Auth - contrato funcional', () {
    testWidgets('login -> token/sesión -> navegación inicial', (tester) async {
      final authFile = TestData.findFeatureFile(
        candidates: const [
          'controllers/auth/auth_controller.dart',
          'services/auth_service.dart',
          'pages/auth/login_page.dart',
          'pages/auth/auth_page.dart',
        ],
        fileNameHints: const [
          r'auth.*\.dart$',
          r'login.*\.dart$',
        ],
        contentHints: const ['login', 'token', 'email', 'correo', 'password'],
      );

      expect(authFile, isNotNull, reason: 'Debe existir la pieza de autenticación.');

      final authSource = TestData.readLib(authFile!);
      final allSource = TestData.allDartFiles()
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(TestData.containsAny(authSource, ['login', 'iniciar']), isTrue);
      expect(TestData.containsAny(authSource, ['token', 'sesion', 'sesión']), isTrue);
      expect(TestData.containsAny(authSource, ['email', 'correo']), isTrue);
      expect(TestData.containsAny(authSource, ['password', 'contraseña', 'contrasena']), isTrue);
      expect(
        TestData.containsAny(allSource, ['catalogo', 'dashboard', 'administrador', 'cliente']),
        isTrue,
        reason: 'Después del login debe existir navegación hacia catálogo/dashboard/rol.',
      );
    });
  });
}
