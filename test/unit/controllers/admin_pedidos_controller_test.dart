import 'package:flutter_test/flutter_test.dart';
import 'package:store_mood_app/core/testing/domain_test_harness.dart';
import 'package:store_mood_app/core/utils/money_utils.dart';

void main() {
  group('Administración de pedidos - reglas testeables', () {
    test('normaliza estado con espacios', () {
      expect(AdminPedidoRules.normalizeStatus('Pago Aprobado'), 'pago_aprobado');
    });

    test('permite despachar pago aprobado', () {
      expect(AdminPedidoRules.canDispatch('pago_aprobado'), isTrue);
    });

    test('permite despachar pendiente de bodega', () {
      expect(AdminPedidoRules.canDispatch('pendiente_bodega'), isTrue);
    });

    test('no permite despachar cancelado', () {
      expect(AdminPedidoRules.canDispatch('cancelado'), isFalse);
    });

    test('permite cancelar pedido pendiente', () {
      expect(AdminPedidoRules.canCancel('pendiente_revision'), isTrue);
    });

    test('no permite cancelar pedido despachado', () {
      expect(AdminPedidoRules.canCancel('despachado'), isFalse);
    });

    test('filtra pedidos por estado', () {
      final filtered = AdminPedidoRules.filterByStatus(StoreMoodFixtures.pedidos(), 'despachado');
      expect(filtered.length, 1);
      expect(filtered.first.codigo, 'PED-003');
    });

    test('genera resumen por estados', () {
      final resumen = AdminPedidoRules.resumen(StoreMoodFixtures.pedidos());
      expect(resumen['pago_aprobado'], 1);
      expect(resumen['pendiente_bodega'], 1);
      expect(resumen['despachado'], 1);
    });

    test('calcula cartera total de pedidos', () {
      expect(AdminPedidoRules.totalCarteraCents(StoreMoodFixtures.pedidos()), 95000);
    });

    test('genera código de despacho y formato monetario', () {
      final pedido = StoreMoodFixtures.pedidos().first;
      expect(AdminPedidoRules.buildDispatchCode(pedido), 'DSP-PED-001');
      expect(MoneyUtils.formatCordobas(pedido.totalCents), 'C\$ 550.00');
    });
  });
}
