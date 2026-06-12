import 'package:flutter/foundation.dart';

import '../../models/catalogo/pedido_model.dart';
import '../../services/catalogo_service.dart';

class PedidosController extends ChangeNotifier {
  final CatalogoService _service;

  PedidosController({CatalogoService? service})
      : _service = service ?? CatalogoService();

  bool loading = false;
  bool saving = false;
  String? error;

  List<PedidoModel> pedidos = <PedidoModel>[];
  PedidoModel? seleccionado;

  Future<void> cargarPedidos() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      pedidos = await _service.listarPedidos();
    } catch (e) {
      error = _parseError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PedidoModel?> verDetalle(int pedidoId) async {
    loading = true;
    error = null;
    seleccionado = null;
    notifyListeners();

    try {
      seleccionado = await _service.verPedido(pedidoId);
      return seleccionado;
    } catch (e) {
      error = _parseError(e);
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
    saving = true;
    error = null;
    notifyListeners();

    try {
      seleccionado = await _service.corregirReferenciaTransferencia(
        pedidoId: pedidoId,
        referenciaTransferencia: referenciaTransferencia,
        observacion: observacion,
      );

      await cargarPedidos();
      return true;
    } catch (e) {
      error = _parseError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  /// Cancela un pedido rechazado desde el lado cliente.
  /// El backend debe:
  /// 1) validar que el pedido pertenezca al usuario autenticado;
  /// 2) validar que el pago esté rechazado;
  /// 3) devolver stock;
  /// 4) borrar registros relacionados del pedido.
  Future<bool> cancelarPedidoRechazado({required int pedidoId}) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
      final ok = await _service.cancelarPedidoRechazado(pedidoId);

      if (ok) {
        pedidos.removeWhere((pedido) => pedido.id == pedidoId);
        if (seleccionado?.id == pedidoId) {
          seleccionado = null;
        }

        await cargarPedidos();
      }

      return ok;
    } catch (e) {
      error = _parseError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String _parseError(Object e) {
    final text = e.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return text;
  }
}
