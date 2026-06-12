import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_data.dart';

void main() {
  group('Estructura general de tests y lib', () {
    test('el proyecto tiene pubspec.yaml y carpeta lib', () {
      final root = TestData.projectRoot();

      expect(root.path, isNotEmpty);
      expect(TestData.libRoot().existsSync(), isTrue);
    });

    test('existe al menos un archivo Dart dentro de lib', () {
      expect(TestData.allDartFiles(), isNotEmpty);
    });

    test('los archivos Dart encontrados no tienen conflictos Git reales', () {
      final files = TestData.allDartFiles();

      for (final file in files) {
        final source = file.readAsStringSync();
        expect(
          TestData.hasRealMergeConflictMarkers(source),
          isFalse,
          reason: 'Hay conflicto Git real en ${file.path}',
        );
      }
    });

    test('los fixtures mínimos de prueba están configurados', () {
      expect(TestData.testEmail, contains('@'));
      expect(TestData.testPassword.length, greaterThanOrEqualTo(6));
      expect(TestData.testToken, isNotEmpty);
      expect(TestData.productoJson['precio'], greaterThan(0));
      expect(TestData.carritoJson['subtotal'], greaterThan(0));
      expect(TestData.pedidoJson['total'], greaterThan(0));
    });
  });
}
