import 'package:flutter/foundation.dart';

import '../../models/catalogo/pedido_checkout_models.dart';
import '../../services/checkout_pedidos_service.dart';

class PedidoCheckoutController extends ChangeNotifier {
  final CheckoutPedidosService service;

  PedidoCheckoutController(this.service);

  bool loading = false;
  String? error;
  String? message;
  List<MetodoPagoCheckout> metodosPago = [];
  MetodoPagoCheckout? metodoSeleccionado;
  PreviewEnvioCheckout? previewEnvio;

  Future<void> iniciar({
    required int departamentoId,
    required double subtotal,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        service.listarMetodosPago(),
        service.previewEnvio(departamentoId: departamentoId, subtotal: subtotal),
      ]);

      metodosPago = results[0] as List<MetodoPagoCheckout>;
      previewEnvio = results[1] as PreviewEnvioCheckout;
      if (metodosPago.isNotEmpty) metodoSeleccionado = metodosPago.first;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void seleccionarMetodo(MetodoPagoCheckout? metodo) {
    metodoSeleccionado = metodo;
    notifyListeners();
  }

  Future<bool> confirmarPedido({
    required String referenciaTransferencia,
    String? observacion,
  }) async {
    if (metodoSeleccionado == null) {
      error = 'Selecciona un método de pago.';
      notifyListeners();
      return false;
    }

    if (referenciaTransferencia.trim().isEmpty) {
      error = 'Escribe la referencia de la transferencia.';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    message = null;
    notifyListeners();

    try {
      final json = await service.realizarPedido(
        metodoPagoId: metodoSeleccionado!.id,
        referenciaTransferencia: referenciaTransferencia.trim(),
        observacion: observacion,
      );
      message = json['message']?.toString() ?? 'Pedido realizado correctamente.';
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
