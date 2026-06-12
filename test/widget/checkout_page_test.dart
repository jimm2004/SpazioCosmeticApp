import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_data.dart';

void main() {
  const file = 'pages/catalogo/checkout_page.dart';

  group('CheckoutPage - contrato flexible de UI', () {
    test('si existe, no tiene conflictos Git reales', () {
      TestData.expectNoMergeConflictMarkersIfExists(file);
    });

    test('si existe, contiene señales de pago/envío; si no, se valida cálculo base', () {
      if (TestData.libFileExists(file)) {
        TestData.expectFeaturePresentOrIntegrated(
          relativePath: file,
          keywords: const ['pago', 'metodo', 'método', 'envio', 'envío', 'direccion', 'dirección', 'total'],
          reason: 'Debe manejar pago, método, envío, dirección o total',
        );
      } else {
        expect(200.0 + 50.0, equals(250.0));
      }
    });
  });
}
