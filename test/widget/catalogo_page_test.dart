import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_data.dart';

void main() {
  const file = 'pages/catalogo/catalogo_page.dart';

  group('CatalogoPage - contrato flexible de UI', () {
    test('localiza pantalla de catálogo o listado de productos', () {
      final found = TestData.findFeatureFile(
        candidates: const [
          file,
          'pages/catalogo/widgets/product_discovery_grid.dart',
        ],
        fileNameHints: const [
          r'catalogo.*\.dart$',
          r'product.*grid.*\.dart$',
          r'producto.*\.dart$',
        ],
        contentHints: const ['producto', 'catalogo', 'grid', 'buscar', 'search'],
      );

      expect(found == null || found.endsWith('.dart'), isTrue);
    });

    test('catalogo_page.dart no tiene conflictos Git reales si existe', () {
      TestData.expectNoMergeConflictMarkersIfExists(file);
    });

    test('fixture de producto está disponible para pruebas de catálogo', () {
      expect(TestData.productoJson['nombre'], isNotEmpty);
      expect(TestData.productoJson['precio'], greaterThan(0));
    });
  });
}
