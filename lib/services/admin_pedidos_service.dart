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
    final json = await api.get(
      '/admin/pedidos',
      query: {
        'estado_pago': estadoPago,
        'estado_pedido_id': estadoPedidoId,
        'banco': banco,
        'moneda': moneda,
        'buscar': buscar,
        'fecha_desde': fechaDesde,
        'fecha_hasta': fechaHasta,
      },
    );

    return AdminPedidosResponse.fromJson(Map<String, dynamic>.from(json));
  }

  Future<AdminPedidoFull> verPedido(int pedidoId) async {
    final json = await api.get('/admin/pedidos/$pedidoId');
    return AdminPedidoFull.fromJson(Map<String, dynamic>.from(json));
  }

  /// Devuelve el JSON crudo del endpoint de detalle.
  /// Se usa para armar la vista previa y PDF de despacho sin depender de nombres internos del modelo.
  Future<Map<String, dynamic>> verPedidoParaDocumento(int pedidoId) async {
    final json = await api.get('/admin/pedidos/$pedidoId');
    return Map<String, dynamic>.from(json);
  }

  Future<dynamic> historialPedido(int pedidoId) async {
    return api.get('/admin/pedidos/$pedidoId/historial');
  }

  Future<String> aprobarTransferencia(int pedidoId) async {
    final json = await api.post('/admin/pedidos/$pedidoId/aprobar-transferencia');
    return _message(json, 'Transferencia aprobada correctamente. Pedido enviado a despacho.');
  }

  Future<String> rechazarTransferencia(int pedidoId, {String? motivo}) async {
    final json = await api.post(
      '/admin/pedidos/$pedidoId/rechazar-transferencia',
      body: {
        'motivo': motivo?.trim().isNotEmpty == true
            ? motivo!.trim()
            : 'La referencia de transferencia no pudo ser validada por contabilidad.',
      },
    );

    return _message(json, 'Transferencia rechazada. Se notificó al cliente para corregir la referencia.');
  }

  Future<String> despacharPedido(int pedidoId) async {
    final json = await api.post('/admin/pedidos/$pedidoId/despachar');
    return _message(json, 'Pedido despachado correctamente. Se notificó al cliente por correo.');
  }

  Future<AdminPedidosResponse> listarPendientesContabilidad({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return listarPedidos(
      estadoPago: 'pendiente_revision',
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<AdminPedidosResponse> listarRechazadosContabilidad({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return listarPedidos(
      estadoPago: 'rechazado',
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<AdminPedidosResponse> listarPendientesDespacho({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return listarPedidos(
      estadoPago: 'aprobado',
      estadoPedidoId: 3,
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<AdminPedidosResponse> listarDespachados({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return listarPedidos(
      estadoPedidoId: 4,
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  String _message(dynamic json, String fallback) {
    if (json is Map && json['message'] != null) {
      return json['message'].toString();
    }
    return fallback;
  }
}
