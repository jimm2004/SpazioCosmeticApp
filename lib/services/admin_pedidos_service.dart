import '../models/admin/admin_pedido_model.dart';
import 'mood_api_client.dart';

class AdminPedidosService {
  final MoodApiClient api;

  const AdminPedidosService(this.api);

  Future<AdminPedidosResponse> listarPedidos({
    String? estadoPago,
    int? estadoPedidoId,
    String? banco,
    String? moneda,
    String? buscar,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final json = await api.get('/admin/pedidos', query: {
      'estado_pago': estadoPago,
      'estado_pedido_id': estadoPedidoId,
      'banco': banco,
      'moneda': moneda,
      'buscar': buscar,
      'fecha_desde': fechaDesde,
      'fecha_hasta': fechaHasta,
    });

    return AdminPedidosResponse.fromJson(Map<String, dynamic>.from(json));
  }

  Future<AdminPedidoFull> verPedido(int pedidoId) async {
    final json = await api.get('/admin/pedidos/$pedidoId');
    return AdminPedidoFull.fromJson(Map<String, dynamic>.from(json));
  }

  Future<String> aprobarTransferencia(int pedidoId) async {
    final json = await api.post('/admin/pedidos/$pedidoId/aprobar-transferencia');
    return _message(json, 'Transferencia aprobada.');
  }

  Future<String> rechazarTransferencia(int pedidoId, {String? motivo}) async {
    final json = await api.post(
      '/admin/pedidos/$pedidoId/rechazar-transferencia',
      body: {'motivo': motivo},
    );
    return _message(json, 'Transferencia rechazada.');
  }

  Future<String> despacharPedido(int pedidoId) async {
    final json = await api.post('/admin/pedidos/$pedidoId/despachar');
    return _message(json, 'Pedido despachado.');
  }

  String _message(dynamic json, String fallback) {
    if (json is Map && json['message'] != null) return json['message'].toString();
    return fallback;
  }
}
