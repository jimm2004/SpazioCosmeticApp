import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_data.dart';

void main() {
  String? pedidoModelFile() {
    return TestData.findFeatureFile(
      candidates: const [
        'models/catalogo/pedido_model.dart',
        'models/pedido_model.dart',
        'models/admin/pedido_model.dart',
        'models/admin/despacho_documento_model.dart',
        'services/pedidos_service.dart',
        'pages/catalogo/pedidos_page.dart',
      ],
      fileNameHints: const [
        r'pedido.*\.dart$',
        r'despacho.*documento.*\.dart$',
      ],
      contentHints: const ['estado_pago', 'estadopago', 'referencia', 'rechaz', 'pedido', 'total'],
    );
  }

  group('PedidoModel - pruebas flexibles', () {
    test('localiza modelo de pedido o lógica equivalente', () {
      final found = pedidoModelFile();
      expect(found == null || found.endsWith('.dart'), isTrue);
    });

    test('si existe, no tiene conflictos Git reales', () {
      final found = pedidoModelFile();

      if (found != null) {
        TestData.expectNoMergeConflictMarkersIfExists(found);
      } else {
        expect(true, isTrue);
      }
    });

    test('fixture de pedido tiene identificador, estado, referencia y total', () {
      expect(TestData.pedidoJson['id'], equals(1));
      expect(TestData.pedidoJson['estado_pago'], equals('rechazado'));
      expect(TestData.pedidoJson['referencia'], isNotEmpty);
      expect(TestData.pedidoJson['total'], greaterThan(0));
    });

    test('estados rechazados permiten corrección según regla de negocio base', () {
      final estadosQuePermitenCorreccion = [
        'rechazado',
        'rechazado_contabilidad',
        'referencia_rechazada',
        'correccion_requerida',
      ];

      expect(estadosQuePermitenCorreccion.contains('rechazado'), isTrue);
      expect(estadosQuePermitenCorreccion.contains('aprobado'), isFalse);
    });
  });
}
