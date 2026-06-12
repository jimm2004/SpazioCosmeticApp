import 'package:flutter/foundation.dart';

import '../../models/admin/admin_pedido_model.dart';
import '../../models/admin/despacho_documento_model.dart';
import '../../services/admin_pedidos_service.dart';

class AdminPedidosController extends ChangeNotifier {
  final AdminPedidosService service;

  AdminPedidosController(this.service);

  bool loading = false;
  bool preparingDespacho = false;
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
  DespachoDocumentoData? documentoDespacho;

  void limpiarMensaje() {
    lastMessage = null;
    error = null;
    notifyListeners();
  }

  void limpiarDetalle() {
    pedidoSeleccionado = null;
    documentoDespacho = null;
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

  Future<DespachoDocumentoData?> prepararDocumentoDespacho(int pedidoId) async {
    preparingDespacho = true;
    error = null;
    lastMessage = null;
    documentoDespacho = null;
    notifyListeners();

    try {
      final raw = await service.verPedidoParaDocumento(pedidoId);
      final documento = DespachoDocumentoData.fromAdminPedidoApi(raw);

      if (documento.pedidoId <= 0) {
        throw Exception('No se pudo identificar el pedido para despacho.');
      }

      documentoDespacho = documento;
      lastMessage = 'Vista de despacho preparada para ${documento.codigoPedido}.';
      return documento;
    } catch (e) {
      error = _parseError(e);
      return null;
    } finally {
      preparingDespacho = false;
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
      lastMessage = await service.rechazarTransferencia(pedidoId, motivo: motivo);
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
      await cargarPendientesDespacho();
    } catch (e) {
      error = _parseError(e);
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> limpiarRechazoPedido(int pedidoId) async {
    loading = true;
    error = null;
    lastMessage = null;
    notifyListeners();

    try {
      lastMessage = await service.limpiarRechazoPedido(pedidoId);
      await cargarRechazadosContabilidad();
      return true;
    } catch (e) {
      error = _parseError(e);
      return false;
    } finally {
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
    if (text.startsWith('Exception: ')) return text.replaceFirst('Exception: ', '');
    return text;
  }
}
