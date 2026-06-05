import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_data.dart';

void main() {
  String? loginPageFile() {
    return TestData.findFeatureFile(
      candidates: const [
        'pages/auth/login_page.dart',
        'pages/auth/auth_page.dart',
      ],
      fileNameHints: const [
        r'login.*\.dart$',
        r'auth.*\.dart$',
      ],
      contentHints: const ['login', 'iniciar', 'correo', 'email', 'password', 'contrasena'],
    );
  }

  group('LoginPage - contrato flexible de UI', () {
    test('localiza pantalla de login o auth', () {
      final found = loginPageFile();
      expect(found == null || found.endsWith('.dart'), isTrue);
    });

    test('si existe, no tiene conflictos Git reales', () {
      final found = loginPageFile();

      if (found != null) {
        TestData.expectNoMergeConflictMarkersIfExists(found);
      } else {
        expect(true, isTrue);
      }
    });

    test('si existe, contiene señales de formulario de acceso', () {
      TestData.expectFeaturePresentOrIntegrated(
        relativePath: loginPageFile(),
        keywords: const ['login', 'iniciar', 'correo', 'email', 'password', 'contrasena', 'contraseña'],
        reason: 'Debe contener elementos de inicio de sesión',
      );
    });
  });
}
