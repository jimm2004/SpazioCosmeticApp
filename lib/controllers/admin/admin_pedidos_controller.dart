import 'package:flutter/foundation.dart';

import '../../models/admin/admin_pedido_model.dart';
import '../../services/admin_pedidos_service.dart';

class AdminPedidosController extends ChangeNotifier {
  final AdminPedidosService service;

  AdminPedidosController(this.service);

  bool loading = false;
  String? error;
  String? lastMessage;

  AdminPedidosResumen resumen = const AdminPedidosResumen(
    pendientesRevision: 0,
    pagosAprobados: 0,
    pagosRechazados: 0,
    pendientesBodega: 0,
    despachados: 0,
  );

  List<AdminPedido> pedidos = [];
  AdminPedidoFull? pedidoSeleccionado;

  void limpiarMensaje() {
    lastMessage = null;
    error = null;
    notifyListeners();
  }

  void limpiarDetalle() {
    pedidoSeleccionado = null;
    notifyListeners();
  }

  Future<void> cargar({
    String? estadoPago,
    int? estadoPedidoId,
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final response = await service.listarPedidos(
        estadoPago: estadoPago,
        estadoPedidoId: estadoPedidoId,
        buscar: buscar,
        banco: banco,
        moneda: moneda,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );

      resumen = response.resumen;
      pedidos = response.pedidos;
    } catch (e) {
      error = _parseError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarPendientesContabilidad({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return cargar(
      estadoPago: 'pendiente_revision',
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<void> cargarRechazadosContabilidad({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return cargar(
      estadoPago: 'rechazado',
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<void> cargarPendientesDespacho({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return cargar(
      estadoPago: 'aprobado',
      estadoPedidoId: 3,
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<void> cargarDespachados({
    String? buscar,
    String? banco,
    String? moneda,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return cargar(
      estadoPedidoId: 4,
      buscar: buscar,
      banco: banco,
      moneda: moneda,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<void> cargarDetalle(int pedidoId) async {
    loading = true;
    error = null;
    pedidoSeleccionado = null;
    notifyListeners();

    try {
      pedidoSeleccionado = await service.verPedido(pedidoId);
    } catch (e) {
      error = _parseError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> aprobar(int pedidoId) async {
    loading = true;
    error = null;
    lastMessage = null;
    notifyListeners();

    try {
      lastMessage = await service.aprobarTransferencia(pedidoId);

      // Después de aprobar, el pedido sale de contabilidad
      // y pasa a la cola de despacho.
      await cargarPendientesContabilidad();
    } catch (e) {
      error = _parseError(e);
      loading = false;
      notifyListeners();
    }
  }

  Future<void> rechazar(int pedidoId, {String? motivo}) async {
    loading = true;
    error = null;
    lastMessage = null;
    notifyListeners();

    try {
      lastMessage = await service.rechazarTransferencia(
        pedidoId,
        motivo: motivo,
      );

      // Después de rechazar, sale de pendientes y queda esperando
      // corrección del cliente.
      await cargarPendientesContabilidad();
    } catch (e) {
      error = _parseError(e);
      loading = false;
      notifyListeners();
    }
  }

  Future<void> despachar(int pedidoId) async {
    loading = true;
    error = null;
    lastMessage = null;
    notifyListeners();

    try {
      lastMessage = await service.despacharPedido(pedidoId);

      // Después de despachar, el pedido ya no debe aparecer
      // en la cola de despacho.
      await cargarPendientesDespacho();
    } catch (e) {
      error = _parseError(e);
      loading = false;
      notifyListeners();
    }
  }

  bool puedeDespacharse(AdminPedido pedido) {
    return pedido.estadoPago == 'aprobado' && pedido.estadoPedidoId == 3;
  }

  bool requiereCorreccionReferencia(AdminPedido pedido) {
    return pedido.estadoPago == 'rechazado';
  }

  String _parseError(Object e) {
    final text = e.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }

    return text;
  }
}