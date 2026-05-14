import 'package:flutter/foundation.dart';

import '../../models/catalogo/pedido_model.dart';
import '../../services/catalogo_service.dart';

class PedidosController extends ChangeNotifier {
  final CatalogoService _service = CatalogoService();

  List<PedidoModel> pedidos = [];
  PedidoModel? seleccionado;
  bool loading = false;
  bool saving = false;
  String? error;
  String? message;

  Future<void> cargarPedidos() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      pedidos = await _service.listarPedidos();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PedidoModel?> verDetalle(int pedidoId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      seleccionado = await _service.verPedido(pedidoId);
      return seleccionado;
    } catch (e) {
      error = _cleanError(e);
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> corregirReferencia({
    required int pedidoId,
    required String referenciaTransferencia,
    String observacion = '',
  }) async {
    if (referenciaTransferencia.trim().isEmpty) {
      error = 'Ingresá la nueva referencia de transferencia.';
      notifyListeners();
      return false;
    }

    saving = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      final pedido = await _service.corregirReferenciaTransferencia(
        pedidoId: pedidoId,
        referenciaTransferencia: referenciaTransferencia.trim(),
        observacion: observacion.trim(),
      );
      seleccionado = pedido;
      final index = pedidos.indexWhere((p) => p.id == pedidoId);
      if (index >= 0) pedidos[index] = pedido;
      message = 'Referencia actualizada. El pedido volvió a revisión contable.';
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}
