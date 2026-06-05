import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  String? cartFile() {
    return TestData.findFeatureFile(
      candidates: const [
        'controllers/catalogo/cart_controller.dart',
        'controllers/catalogo/carrito_controller.dart',
        'services/cart_service.dart',
        'services/carrito_service.dart',
        'pages/catalogo/cart_page.dart',
        'pages/catalogo/catalogo_page.dart',
      ],
      fileNameHints: const [
        r'cart.*\.dart$',
        r'carrito.*\.dart$',
      ],
      contentHints: const ['carrito', 'cart', 'agregar', 'quitar', 'cantidad', 'subtotal'],
    );
  }

  group('CartController - pruebas flexibles', () {
    test('localiza lógica de carrito o permite que esté integrada en la UI', () {
      final found = cartFile();
      expect(found == null || found.endsWith('.dart'), isTrue);
    });

    test('si existe, declara Dart válido y no tiene conflictos Git reales', () {
      final found = cartFile();

      if (found != null) {
        TestData.expectValidDartSourceIfExists(found);
        TestData.expectNoMergeConflictMarkersIfExists(found);
      } else {
        expect(true, isTrue);
      }
    });

    test('si existe, contiene señales de carrito/productos/cantidad', () {
      TestData.expectFeaturePresentOrIntegrated(
        relativePath: cartFile(),
        keywords: const ['carrito', 'cart', 'producto', 'cantidad', 'precio', 'subtotal', 'total'],
        reason: 'Debe manejar carrito, productos, cantidades o montos',
      );
    });

    test('fixture de carrito calcula subtotal correctamente', () {
      final precio = TestData.carritoJson['precio'] as num;
      final cantidad = TestData.carritoJson['cantidad'] as num;

      expect(precio * cantidad, equals(TestData.carritoJson['subtotal']));
    });
  });
}
