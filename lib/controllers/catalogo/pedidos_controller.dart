import 'package:flutter/foundation.dart';

import '../../models/catalogo/pedido_model.dart';
import '../../services/catalogo_service.dart';

class PedidosController extends ChangeNotifier {
  final CatalogoService _service;

  PedidosController({CatalogoService? service}) : _service = service ?? CatalogoService();

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
      pedidos.sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PedidoModel?> verDetalle(int id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      seleccionado = await _service.verPedido(id);
      return seleccionado;
    } catch (e) {
      error = _friendlyError(e);
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
      error = 'Ingresá la nueva referencia.';
      notifyListeners();
      return false;
    }
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
      error = _friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? 'No se pudieron cargar los pedidos.' : text;
  }
}
