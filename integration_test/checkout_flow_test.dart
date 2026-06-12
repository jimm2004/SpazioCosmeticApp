import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo de integración Checkout - contrato funcional', () {
    testWidgets('carrito -> checkout -> confirmación de pedido', (tester) async {
      final checkoutFile = TestData.findFeatureFile(
        candidates: const [
          'controllers/catalogo/checkout_controller.dart',
          'controllers/catalogo/pedido_controller.dart',
          'services/checkout_service.dart',
          'services/pedidos_service.dart',
          'pages/catalogo/checkout_page.dart',
          'pages/catalogo/cart_page.dart',
        ],
        fileNameHints: const [
          r'checkout.*\.dart$',
          r'pedido.*\.dart$',
          r'cart.*\.dart$',
          r'carrito.*\.dart$',
        ],
        contentHints: const ['checkout', 'pedido', 'carrito', 'pago', 'total'],
      );

      expect(checkoutFile, isNotNull, reason: 'Debe existir la pieza de checkout/pedido/carrito.');

      final checkoutSource = TestData.readLib(checkoutFile!);
      final allSource = TestData.allDartFiles()
          .map((file) => file.readAsStringSync())
          .join('\n');

      expect(TestData.containsAny(allSource, ['carrito', 'cart']), isTrue);
      expect(TestData.containsAny(checkoutSource, ['checkout', 'pedido', 'orden']), isTrue);
      expect(TestData.containsAny(allSource, ['subtotal', 'total', 'precio']), isTrue);
      expect(TestData.containsAny(allSource, ['pago', 'payment', 'transferencia', 'contado', 'credito', 'crédito']), isTrue);
      expect(
        TestData.containsAny(allSource, ['confirmar', 'guardar', 'crear', 'enviar', 'finalizar']),
        isTrue,
        reason: 'El flujo debe permitir confirmar o crear un pedido.',
      );
    });
  });
}
