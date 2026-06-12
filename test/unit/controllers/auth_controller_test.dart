import 'package:flutter_test/flutter_test.dart';
import 'package:store_mood_app/core/testing/domain_test_harness.dart';

void main() {
  group('Autenticación - reglas testeables', () {
    test('normaliza correo eliminando espacios y mayúsculas', () {
      expect(AuthRules.normalizeEmail('  CLIENTE@MOOD.COM  '), 'cliente@mood.com');
    });

    test('valida correo correcto', () {
      expect(AuthRules.isValidEmail('cliente@mood.com'), isTrue);
    });

    test('rechaza correo incorrecto', () {
      expect(AuthRules.isValidEmail('cliente-mood'), isFalse);
    });

    test('valida login con credenciales correctas', () {
      expect(() => AuthRules.validateLogin('cliente@mood.com', '123456'), returnsNormally);
    });

    test('rechaza login sin correo', () {
      expect(() => AuthRules.validateLogin('', '123456'), throwsArgumentError);
    });

    test('rechaza contraseña vacía', () {
      expect(() => AuthRules.validateLogin('cliente@mood.com', ''), throwsArgumentError);
    });

    test('rechaza contraseña menor a seis caracteres', () {
      expect(() => AuthRules.validatePassword('123'), throwsArgumentError);
    });

    test('normaliza rol administrador', () {
      expect(AuthRules.normalizeRole('Administrador'), 'administrador');
    });

    test('normaliza rol administración contable con acento', () {
      expect(AuthRules.normalizeRole('Administración Contable'), 'administracion_contable');
    });

    test('resuelve ruta de cliente hacia catálogo', () {
      expect(AuthRules.routeForRole('cliente'), '/catalogo');
    });

    test('extrae token desde respuesta de login', () {
      final response = StoreMoodFixtures.loginResponse();
      expect(AuthRules.extractToken(response), 'token-demo-123');
    });

    test('construye sesión normalizada desde respuesta del servidor', () {
      final session = AuthRules.sessionFromResponse(StoreMoodFixtures.loginResponse(role: 'Admin'));
      expect(session['role'], 'admin');
      expect(session['route'], '/admin');
      expect(session['email'], 'cliente@mood.com');
    });
  });
}
