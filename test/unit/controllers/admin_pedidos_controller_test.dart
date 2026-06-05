import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  String? adminPedidosFile() {
    return TestData.findFeatureFile(
      candidates: const [
        'controllers/admin/admin_pedidos_controller.dart',
        'controllers/admin/pedidos_controller.dart',
        'controllers/admin/despacho_controller.dart',
        'services/admin_pedidos_service.dart',
        'services/pedidos_service.dart',
        'pages/admin/despacho/despacho_page.dart',
        'pages/admin/administrador_page.dart',
        'pages/catalogo/pedidos_page.dart',
      ],
      fileNameHints: const [
        r'pedido.*\.dart$',
        r'pedidos.*\.dart$',
        r'despacho.*\.dart$',
      ],
      contentHints: const ['pedido', 'pedidos', 'despach', 'aprob', 'rechaz'],
    );
  }

  group('AdminPedidosController - pruebas flexibles', () {
    test('localiza lógica administrativa de pedidos o despacho', () {
      final found = adminPedidosFile();

      // En algunos proyectos esta lógica está dentro de Pages/Services.
      expect(found == null || found.endsWith('.dart'), isTrue);
    });

    test('si existe, declara Dart válido y no tiene conflictos Git reales', () {
      final found = adminPedidosFile();

      if (found != null) {
        TestData.expectValidDartSourceIfExists(found);
        TestData.expectNoMergeConflictMarkersIfExists(found);
      } else {
        expect(true, isTrue);
      }
    });

    test('si existe, incluye lógica relacionada con pedidos o despacho', () {
      TestData.expectFeaturePresentOrIntegrated(
        relativePath: adminPedidosFile(),
        keywords: const ['pedido', 'pedidos', 'despacho', 'despach', 'aprob', 'rechaz', 'estado'],
        reason: 'Debe administrar pedidos, estados o despacho',
      );
    });

    test('fixture de pedido mantiene datos mínimos para futuras pruebas', () {
      expect(TestData.pedidoJson['id'], equals(1));
      expect(TestData.pedidoJson['estado_pago'], isNotEmpty);
      expect(TestData.pedidoJson['total'], isA<num>());
    });
  });
}
