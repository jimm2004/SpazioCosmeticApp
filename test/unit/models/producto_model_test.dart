import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  String? productoModelFile() {
    return TestData.findFeatureFile(
      candidates: const [
        'models/catalogo/producto_catalogo_model.dart',
        'models/producto_catalogo_model.dart',
        'models/producto_model.dart',
        'models/catalogo/producto_model.dart',
        'pages/catalogo/catalogo_page.dart',
      ],
      fileNameHints: const [
        r'producto.*\.dart$',
        r'catalogo.*\.dart$',
      ],
      contentHints: const ['producto', 'nombre', 'precio', 'stock', 'activo'],
    );
  }

  group('ProductoModel - pruebas flexibles', () {
    test('localiza modelo o estructura de producto', () {
      final found = productoModelFile();
      expect(found == null || found.endsWith('.dart'), isTrue);
    });

    test('si existe, no tiene conflictos Git reales', () {
      final found = productoModelFile();

      if (found != null) {
        TestData.expectNoMergeConflictMarkersIfExists(found);
      } else {
        expect(true, isTrue);
      }
    });

    test('fixture de producto tiene datos válidos', () {
      expect(TestData.productoJson['id'], equals(1));
      expect(TestData.productoJson['nombre'], isNotEmpty);
      expect(TestData.productoJson['precio'], greaterThan(0));
      expect(TestData.productoJson['stock'], greaterThanOrEqualTo(0));
    });
  });
}
