import 'package:flutter/foundation.dart';

import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/metodo_pago_model.dart';
import '../../models/catalogo/pedido_model.dart';
import '../../models/catalogo/tarifa_envio_model.dart';
import '../../models/catalogo/ubicacion_model.dart';
import '../../services/catalogo_service.dart';
import 'cart_controller.dart';

class CheckoutController extends ChangeNotifier {
  final CatalogoService _service = CatalogoService();

  DatosClienteModel? datosCliente;
  List<ZonaModel> zonas = [];
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
  double get total => CartController.instance.subtotal + costoEnvio;

  Future<void> cargarInicial() => inicializar();

  Future<void> inicializar() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.obtenerDatosCliente(),
        _service.obtenerZonas(),
        _service.obtenerMetodosPago(),
        _service.obtenerTarifasEnvio(),
      ]);

      datosCliente = results[0] as DatosClienteModel?;
      zonas = results[1] as List<ZonaModel>;
      metodosPago = results[2] as List<MetodoPagoModel>;
      tarifasEnvio = results[3] as List<TarifaEnvioModel>;

      if (metodosPago.isNotEmpty) metodoSeleccionado = metodosPago.first;

      await _cargarUbicacionInicial();
      final dept = _buscarDepartamento(datosCliente?.departamentoId);
      if (datosCliente != null && datosCliente!.zonaId == null && dept?.zonaId != null) {
        datosCliente = datosCliente!.copyWith(zonaId: dept!.zonaId);
      }
      await calcularEnvio();
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarUbicacionInicial() async {
    final zonaId = datosCliente?.zonaId;
    final departamentoId = datosCliente?.departamentoId;

    if (zonaId != null) {
      departamentos = await _service.obtenerDepartamentosPorZona(zonaId);
    } else {
      departamentos = await _service.obtenerDepartamentos();
    }

    if (departamentoId != null) {
      municipios = await _service.obtenerMunicipios(departamentoId);
    } else {
      municipios = [];
    }
  }

  Future<void> seleccionarZona(int? zonaId) async {
    departamentos = [];
    municipios = [];
    datosCliente = (datosCliente ?? DatosClienteModel.empty()).copyWith(
      zonaId: zonaId,
      limpiarDepartamento: true,
      limpiarMunicipio: true,
    );
    notifyListeners();

    if (zonaId != null) {
      try {
        departamentos = await _service.obtenerDepartamentosPorZona(zonaId);
      } catch (e) {
        error = _cleanError(e);
      }
    }
    await calcularEnvioSilencioso();
    notifyListeners();
  }

  Future<void> seleccionarDepartamento(int? departamentoId) async {
    municipios = [];
    datosCliente = (datosCliente ?? DatosClienteModel.empty()).copyWith(
      departamentoId: departamentoId,
      limpiarMunicipio: true,
    );
    notifyListeners();

    if (departamentoId != null) {
      try {
        municipios = await _service.obtenerMunicipios(departamentoId);
      } catch (e) {
        error = _cleanError(e);
      }
    }
    await calcularEnvioSilencioso();
    notifyListeners();
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
      final normalized = _normalizarDatos(datos);
      datosCliente = datosCliente == null
          ? await _service.guardarDatosCliente(normalized)
          : await _service.actualizarDatosCliente(normalized);
      await _cargarUbicacionInicial();
      final dept = _buscarDepartamento(datosCliente?.departamentoId);
      if (datosCliente != null && datosCliente!.zonaId == null && dept?.zonaId != null) {
        datosCliente = datosCliente!.copyWith(zonaId: dept!.zonaId);
      }
      await calcularEnvio();
      return true;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> guardarDatosCliente(DatosClienteModel datos) => guardarDatos(datos);

  DatosClienteModel _normalizarDatos(DatosClienteModel datos) {
    final dept = _buscarDepartamento(datos.departamentoId);
    final zonaId = datos.zonaId ?? dept?.zonaId;
    final zonaNombre = _buscarZonaNombre(zonaId, fallback: datos.zonaNombre);

    return datos.copyWith(
      zonaId: zonaId,
      zonaNombre: zonaNombre,
      departamentoNombre: dept?.nombre ?? datos.departamentoNombre,
    );
  }

  void seleccionarMetodo(MetodoPagoModel metodo) {
    metodoSeleccionado = metodo;
    notifyListeners();
  }

  Future<void> calcularEnvioSilencioso() async {
    try {
      await _calcularEnvioInterno();
    } catch (_) {}
  }

  Future<void> calcularEnvio() async {
    await _calcularEnvioInterno();
    notifyListeners();
  }

  Future<void> _calcularEnvioInterno() async {
    final departamentoId = datosCliente?.departamentoId;
    if (departamentoId == null || CartController.instance.subtotal <= 0) {
      costoEnvio = 0;
      zonaEnvio = '';
      porcentajeEnvio = 0;
      return;
    }

    try {
      final preview = await _service.previewCostoEnvio(
        subtotal: CartController.instance.subtotal,
        departamentoId: departamentoId,
      );
      costoEnvio = _toDouble(preview['costo_envio']);
      zonaEnvio = (preview['zona_nombre'] ?? '').toString();
      porcentajeEnvio = _toDouble(preview['porcentaje_envio']);
    } catch (_) {
      final dept = _buscarDepartamento(departamentoId);
      final tarifa = _buscarTarifaPorZona(dept?.zonaId);
      porcentajeEnvio = tarifa?.porcentajeEnvio ?? 0;
      zonaEnvio = tarifa?.nombreZona ?? '';
      costoEnvio = CartController.instance.subtotal * (porcentajeEnvio / 100);
    }
  }

  Future<PedidoModel?> confirmarPedido({
    required String referenciaTransferencia,
    String observacion = '',
  }) async {
    if (requiereDatosCliente) {
      error = 'Completá zona, departamento, municipio, dirección y referencia antes de pedir.';
      notifyListeners();
      return null;
    }
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
      error = _cleanError(e);
      return null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  DepartamentoModel? _buscarDepartamento(int? departamentoId) {
    if (departamentoId == null) return null;
    for (final item in departamentos) {
      if (item.id == departamentoId) return item;
    }
    return null;
  }

  String _buscarZonaNombre(int? zonaId, {String fallback = ''}) {
    if (zonaId == null) return fallback;
    for (final item in zonas) {
      if (item.id == zonaId) return item.nombreZona;
    }
    return fallback;
  }

  TarifaEnvioModel? _buscarTarifaPorZona(int? zonaId) {
    if (zonaId != null) {
      for (final tarifa in tarifasEnvio) {
        if (tarifa.zonaId == zonaId) return tarifa;
      }
    }
    for (final tarifa in tarifasEnvio) {
      if (tarifa.esDefault) return tarifa;
    }
    return tarifasEnvio.isNotEmpty ? tarifasEnvio.first : null;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}
