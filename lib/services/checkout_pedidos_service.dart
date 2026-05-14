import '../models/catalogo/pedido_checkout_models.dart';
import 'mood_api_client.dart';

class CheckoutPedidosService {
  final MoodApiClient api;

  const CheckoutPedidosService(this.api);

  Future<List<MetodoPagoCheckout>> listarMetodosPago() async {
    final json = await api.get('/catalogo/metodos-pago');
    final data = json is Map && json['data'] is List ? json['data'] as List : const [];

    return data
        .whereType<Map>()
        .map((e) => MetodoPagoCheckout.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.activo)
        .toList();
  }

  Future<PreviewEnvioCheckout> previewEnvio({
    required int departamentoId,
    required double subtotal,
  }) async {
    final json = await api.post('/catalogo/preview-envio', body: {
      'departamento_id': departamentoId,
      'subtotal': subtotal,
    });

    return PreviewEnvioCheckout.fromJson(Map<String, dynamic>.from(json));
  }

  Future<Map<String, dynamic>> realizarPedido({
    required int metodoPagoId,
    required String referenciaTransferencia,
    String? observacion,
  }) async {
    final json = await api.post('/pedidos/realizar', body: {
      'metodo_pago_id': metodoPagoId,
      'referencia_transferencia': referenciaTransferencia,
      'observacion': observacion,
    });

    return Map<String, dynamic>.from(json);
  }

  Future<List<PedidoClienteResumen>> misPedidos() async {
    final json = await api.get('/pedidos');
    final data = json is Map && json['data'] is List ? json['data'] as List : const [];

    return data
        .whereType<Map>()
        .map((e) => PedidoClienteResumen.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> verPedido(int pedidoId) async {
    final json = await api.get('/pedidos/$pedidoId');
    return Map<String, dynamic>.from(json);
  }
}
