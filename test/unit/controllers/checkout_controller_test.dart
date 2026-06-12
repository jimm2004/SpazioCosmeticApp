import 'package:flutter_test/flutter_test.dart';
import 'package:store_mood_app/core/testing/domain_test_harness.dart';

void main() {
  group('Checkout - reglas testeables', () {
    test('acepta método de pago efectivo', () {
      expect(CheckoutRules.isSupportedPaymentMethod('efectivo'), isTrue);
    });

    test('acepta método de pago transferencia', () {
      expect(CheckoutRules.isSupportedPaymentMethod('transferencia'), isTrue);
    });

    test('rechaza método de pago inexistente', () {
      expect(CheckoutRules.isSupportedPaymentMethod('cripto'), isFalse);
    });

    test('valida dirección completa', () {
      expect(() => CheckoutRules.validateAddress('Barrio central, casa 25'), returnsNormally);
    });

    test('rechaza dirección demasiado corta', () {
      expect(() => CheckoutRules.validateAddress('casa'), throwsArgumentError);
    });

    test('calcula total con envío', () {
      expect(CheckoutRules.totalCents(subtotalCents: 55000, shippingCents: 5000), 60000);
    });

    test('calcula total con descuento', () {
      expect(CheckoutRules.totalCents(subtotalCents: 55000, shippingCents: 5000, discountCents: 10000), 50000);
    });

    test('no permite total negativo por descuento excesivo', () {
      expect(CheckoutRules.totalCents(subtotalCents: 5000, shippingCents: 0, discountCents: 10000), 0);
    });

    test('valida checkout completo', () {
      expect(
        () => CheckoutRules.validateCheckout(
          items: StoreMoodFixtures.cart(),
          paymentMethod: 'transferencia',
          address: 'Barrio central, casa 25',
        ),
        returnsNormally,
      );
    });

    test('construye payload de pedido con totales', () {
      final payload = CheckoutRules.buildPayload(
        items: StoreMoodFixtures.cart(),
        paymentMethod: 'Tarjeta',
        address: 'Barrio central, casa 25',
        shippingCents: 5000,
      );
      expect(payload['items'], 2);
      expect(payload['unidades'], 3);
      expect(payload['total_centavos'], 60000);
      expect(payload['metodo_pago'], 'tarjeta');
    });
  });
}
