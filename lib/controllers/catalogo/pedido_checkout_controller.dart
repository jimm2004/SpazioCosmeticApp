import 'package:flutter/foundation.dart';

import '../../models/catalogo/metodo_pago_model.dart';
import '../../models/catalogo/pedido_model.dart';
import '../../services/catalogo_service.dart';

class PedidoCheckoutController extends ChangeNotifier {
  final CatalogoService service;

  PedidoCheckoutController([CatalogoService? service]) : service = service ?? CatalogoService();

  bool loading = false;
  String? error;
  String? message;
  List<MetodoPagoModel> metodosPago = [];
  MetodoPagoModel? metodoSeleccionado;
  Map<String, dynamic>? previewEnvio;

  Future<void> iniciar({
    required int departamentoId,
    required double subtotal,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        service.obtenerMetodosPago(),
        service.previewCostoEnvio(departamentoId: departamentoId, subtotal: subtotal),
      ]);

      metodosPago = results[0] as List<MetodoPagoModel>;
      previewEnvio = results[1] as Map<String, dynamic>;
      if (metodosPago.isNotEmpty) metodoSeleccionado = metodosPago.first;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void seleccionarMetodo(MetodoPagoModel? metodo) {
    metodoSeleccionado = metodo;
    notifyListeners();
  }

  Future<PedidoModel?> confirmarPedido({
    required String referenciaTransferencia,
    String? observacion,
  }) async {
    if (metodoSeleccionado == null) {
      error = 'Seleccioná un método de pago.';
      notifyListeners();
      return null;
    }

    if (referenciaTransferencia.trim().isEmpty) {
      error = 'Escribí la referencia de la transferencia.';
      notifyListeners();
      return null;
    }

    loading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      final pedido = await service.realizarPedido(
        metodoPagoId: metodoSeleccionado!.id,
        referenciaTransferencia: referenciaTransferencia.trim(),
        observacion: observacion ?? '',
      );
      message = 'Pedido realizado correctamente.';
      return pedido;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
