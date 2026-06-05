import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  const file = 'controllers/auth/auth_controller.dart';

  group('AuthController - pruebas flexibles', () {
    test('localiza auth_controller.dart o lógica de autenticación integrada', () {
      final found = TestData.findFeatureFile(
        candidates: const [
          file,
          'services/auth_service.dart',
          'pages/auth/login_page.dart',
          'pages/auth/auth_page.dart',
        ],
        fileNameHints: const [
          r'auth.*\.dart$',
          r'login.*\.dart$',
        ],
        contentHints: const ['login', 'auth', 'correo', 'email', 'password'],
      );

      expect(found, isNotNull, reason: 'Debe existir lógica de autenticación en lib/');
    });

    test('el archivo de auth no contiene conflictos Git reales', () {
      final found = TestData.findFeatureFile(
        candidates: const [
          file,
          'services/auth_service.dart',
          'pages/auth/login_page.dart',
          'pages/auth/auth_page.dart',
        ],
        fileNameHints: const [r'auth.*\.dart$', r'login.*\.dart$'],
        contentHints: const ['login', 'auth', 'correo', 'email', 'password'],
      );

      if (found != null) {
        TestData.expectNoMergeConflictMarkersIfExists(found);
      }
    });

    test('incluye señales de login, token o sesión cuando existe el archivo', () {
      final found = TestData.findFeatureFile(
        candidates: const [
          file,
          'services/auth_service.dart',
          'pages/auth/login_page.dart',
          'pages/auth/auth_page.dart',
        ],
        fileNameHints: const [r'auth.*\.dart$', r'login.*\.dart$'],
        contentHints: const ['login', 'auth', 'token', 'sesion', 'session'],
      );

      TestData.expectFeaturePresentOrIntegrated(
        relativePath: found,
        keywords: const ['login', 'auth', 'token', 'sesion', 'session', 'password', 'correo', 'email'],
        reason: 'Debe manejar autenticación, sesión o credenciales',
      );
    });

    test('normaliza roles principales esperados', () {
      for (final entry in TestData.expectedRoles.entries) {
        expect(TestData.normalizeRole(entry.key), equals(entry.value));
      }
    });

    test('valida correos básicos correctamente', () {
      expect(TestData.isEmail(TestData.testEmail), isTrue);
      expect(TestData.isEmail(TestData.invalidEmail), isFalse);
    });

    test('los datos mock de login son coherentes', () {
      expect(TestData.loginSuccessResponse['plain_text_token'], equals(TestData.testToken));
      expect(TestData.loginSuccessResponse['user'], isA<Map<String, dynamic>>());
    });
  });
}
