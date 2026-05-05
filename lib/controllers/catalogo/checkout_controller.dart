import 'package:flutter/foundation.dart';

import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/metodo_pago_model.dart';
import '../../models/catalogo/tarifa_envio_model.dart';
import '../../models/catalogo/ubicacion_model.dart';
import '../../services/catalogo_service.dart';
import 'cart_controller.dart';

class CheckoutController extends ChangeNotifier {
  final CatalogoService _service = CatalogoService();

  DatosClienteModel? datosCliente;
  List<DepartamentoModel> departamentos = [];
  List<MunicipioModel> municipios = [];
  List<MetodoPagoModel> metodosPago = [];
  List<TarifaEnvioModel> tarifasEnvio = [];

  MetodoPagoModel? metodoSeleccionado;
  double costoEnvio = 0;
  String zonaEnvio = '';
  double porcentajeEnvio = 0;

  bool loading = false;
  bool saving = false;
  String? error;

  bool get requiereDatosCliente => datosCliente == null || !datosCliente!.completo;

  Future<void> cargarInicial() async {
    return inicializar();
  }

  Future<void> inicializar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.obtenerDatosCliente(),
        _service.obtenerDepartamentos(),
        _service.obtenerMetodosPago(),
        _service.obtenerTarifasEnvio(),
      ]);
      datosCliente = results[0] as DatosClienteModel?;
      departamentos = results[1] as List<DepartamentoModel>;
      metodosPago = results[2] as List<MetodoPagoModel>;
      tarifasEnvio = results[3] as List<TarifaEnvioModel>;
      if (metodosPago.isNotEmpty) metodoSeleccionado = metodosPago.first;
      await calcularEnvio();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMunicipios(int departamentoId) async {
    municipios = await _service.obtenerMunicipios(departamentoId);
    notifyListeners();
  }

  Future<bool> guardarDatos(DatosClienteModel datos) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      datosCliente = datosCliente == null
          ? await _service.guardarDatosCliente(datos)
          : await _service.actualizarDatosCliente(datos);
      await calcularEnvio();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> guardarDatosCliente(DatosClienteModel datos) async {
    return guardarDatos(datos);
  }

  void seleccionarMetodo(MetodoPagoModel metodo) {
    metodoSeleccionado = metodo;
    notifyListeners();
  }

  Future<void> calcularEnvio() async {
    try {
      final preview = await _service.previewCostoEnvio(
        subtotal: CartController.instance.subtotal,
        departamentoId: datosCliente?.departamentoId,
        municipioId: datosCliente?.municipioId,
      );
      costoEnvio = _toDouble(preview['costo_envio'] ?? preview['data']?['costo_envio']);
      zonaEnvio = (preview['zona_nombre'] ?? preview['data']?['zona_nombre'] ?? '').toString();
      porcentajeEnvio = _toDouble(preview['porcentaje_envio'] ?? preview['data']?['porcentaje_envio']);
    } catch (_) {
      final tarifa = tarifasEnvio.firstWhere(
        (t) => t.esDefault,
        orElse: () => tarifasEnvio.isNotEmpty
            ? tarifasEnvio.last
            : const TarifaEnvioModel(
                id: 0,
                nombreZona: 'Sin zona',
                porcentajeEnvio: 0,
                esDefault: true,
                descripcion: '',
                activo: true,
              ),
      );
      porcentajeEnvio = tarifa.porcentajeEnvio;
      zonaEnvio = tarifa.nombreZona;
      costoEnvio = CartController.instance.subtotal * (porcentajeEnvio / 100);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> confirmarPedido({
    required String referenciaTransferencia,
    String observacion = '',
  }) async {
    if (metodoSeleccionado == null) {
      error = 'Seleccioná un método de pago.';
      notifyListeners();
      return null;
    }
    if (referenciaTransferencia.trim().isEmpty) {
      error = 'Ingresá la referencia de la transferencia.';
      notifyListeners();
      return null;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.realizarPedido(
        metodoPagoId: metodoSeleccionado!.id,
        referenciaTransferencia: referenciaTransferencia.trim(),
        observacion: observacion.trim(),
      );
      await CartController.instance.cargarCarrito();
      return result;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  double get total => CartController.instance.subtotal + costoEnvio;

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}
