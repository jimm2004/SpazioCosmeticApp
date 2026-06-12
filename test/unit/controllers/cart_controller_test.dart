import 'package:flutter_test/flutter_test.dart';
import 'package:store_mood_app/core/testing/domain_test_harness.dart';
import 'package:store_mood_app/core/utils/money_utils.dart';

void main() {
  group('Carrito - reglas testeables', () {
    test('calcula subtotal de un producto por cantidad', () {
      const item = CartItem(productId: 1, name: 'Labial', unitPriceCents: 10000, quantity: 3);
      expect(item.subtotalCents, 30000);
    });

    test('agrega un producto nuevo al carrito', () {
      final updated = CartRules.addItem([], const CartItem(productId: 1, name: 'Labial', unitPriceCents: 10000, quantity: 1));
      expect(updated.length, 1);
    });

    test('suma cantidades cuando el producto ya existe', () {
      final updated = CartRules.addItem(
        const [CartItem(productId: 1, name: 'Labial', unitPriceCents: 10000, quantity: 1)],
        const CartItem(productId: 1, name: 'Labial', unitPriceCents: 10000, quantity: 2),
      );
      expect(updated.first.quantity, 3);
    });

    test('elimina producto por id', () {
      final updated = CartRules.removeItem(StoreMoodFixtures.cart(), 1);
      expect(updated.any((item) => item.productId == 1), isFalse);
    });

    test('actualiza cantidad de un producto', () {
      final updated = CartRules.updateQuantity(StoreMoodFixtures.cart(), 1, 5);
      expect(updated.firstWhere((item) => item.productId == 1).quantity, 5);
    });

    test('rechaza cantidad cero', () {
      expect(() => CartRules.validateQuantity(0), throwsArgumentError);
    });

    test('rechaza cantidad negativa', () {
      expect(() => CartRules.validateQuantity(-1), throwsArgumentError);
    });

    test('calcula unidades totales del carrito', () {
      expect(CartRules.totalUnits(StoreMoodFixtures.cart()), 3);
    });

    test('calcula subtotal total del carrito en centavos', () {
      expect(CartRules.subtotalCents(StoreMoodFixtures.cart()), 55000);
    });

    test('formatea subtotal del carrito en córdobas', () {
      final total = CartRules.subtotalCents(StoreMoodFixtures.cart());
      expect(MoneyUtils.formatCordobas(total), 'C\$ 550.00');
    });
  });
}
