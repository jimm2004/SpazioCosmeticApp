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

  Future<void> cargar({
    String? estadoPago,
    int? estadoPedidoId,
    String? buscar,
    String? banco,
    String? moneda,
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
      );
      resumen = response.resumen;
      pedidos = response.pedidos;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int pedidoId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      pedidoSeleccionado = await service.verPedido(pedidoId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> aprobar(int pedidoId) async {
    lastMessage = await service.aprobarTransferencia(pedidoId);
    await cargar(estadoPago: 'pendiente_revision');
  }

  Future<void> rechazar(int pedidoId, {String? motivo}) async {
    lastMessage = await service.rechazarTransferencia(pedidoId, motivo: motivo);
    await cargar(estadoPago: 'pendiente_revision');
  }

  Future<void> despachar(int pedidoId) async {
    lastMessage = await service.despacharPedido(pedidoId);
    await cargar(estadoPedidoId: 3);
  }
}
