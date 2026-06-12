import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:store_mood_app/core/testing/domain_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujos de integración Store Mood', () {
    testWidgets('Flujo auth: login válido genera sesión y ruta inicial', (tester) async {
      AuthRules.validateLogin('cliente@mood.com', '123456');
      final session = AuthRules.sessionFromResponse(StoreMoodFixtures.loginResponse());

      expect(session['token'], isNotEmpty);
      expect(session['email'], 'cliente@mood.com');
      expect(session['route'], '/catalogo');
    });

    testWidgets('Flujo checkout: carrito genera payload de pedido confirmado', (tester) async {
      final cart = CartRules.addItem(
        StoreMoodFixtures.cart(),
        const CartItem(productId: 3, name: 'Polvo compacto', unitPriceCents: 20000, quantity: 1),
      );

      final payload = CheckoutRules.buildPayload(
        items: cart,
        paymentMethod: 'transferencia',
        address: 'Barrio central, casa 25',
        shippingCents: 5000,
      );

      expect(payload['items'], 3);
      expect(payload['unidades'], 4);
      expect(payload['subtotal_centavos'], 75000);
      expect(payload['total_centavos'], 80000);
    });
  });
}
