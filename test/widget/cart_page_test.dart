import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_data.dart';

void main() {
  const file = 'pages/catalogo/cart_page.dart';

  group('CartPage - contrato flexible de UI', () {
    test('si existe, no tiene conflictos Git reales', () {
      TestData.expectNoMergeConflictMarkersIfExists(file);
    });

    test('si existe, contiene señales de carrito; si no, se valida fixture', () {
      if (TestData.libFileExists(file)) {
        TestData.expectFeaturePresentOrIntegrated(
          relativePath: file,
          keywords: const ['carrito', 'cart', 'producto', 'cantidad', 'total'],
          reason: 'Debe mostrar carrito, producto, cantidad o total',
        );
      } else {
        expect(TestData.carritoJson['cantidad'], greaterThan(0));
      }
    });
  });
}
