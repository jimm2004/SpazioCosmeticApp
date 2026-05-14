import 'package:flutter/foundation.dart';

import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/metodo_pago_model.dart';
import '../../models/catalogo/pedido_model.dart';
import '../../models/catalogo/ubicacion_model.dart';
import '../../services/catalogo_service.dart';
import 'cart_controller.dart';

class CheckoutController extends ChangeNotifier {
  final CatalogoService _service;

  CheckoutController({CatalogoService? service}) : _service = service ?? CatalogoService();

  bool loading = false;
  bool saving = false;
  String? error;

  DatosClienteModel? datosCliente;
  List<ZonaModel> zonas = <ZonaModel>[];
  List<DepartamentoModel> departamentos = <DepartamentoModel>[];
  List<MunicipioModel> municipios = <MunicipioModel>[];
  List<MetodoPagoModel> metodosPago = <MetodoPagoModel>[];
  MetodoPagoModel? metodoSeleccionado;

  double costoEnvio = 0;
  double porcentajeEnvio = 0;
  String zonaEnvio = '';

  double get subtotal => CartController.instance.subtotal;
  double get total => subtotal + costoEnvio;
  bool get requiereDatosCliente => !(datosCliente?.completo ?? false);

  Future<void> inicializar() => cargar();

  Future<void> cargar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await CartController.instance.cargarCarrito();
      final results = await Future.wait<dynamic>([
        _service.obtenerDatosCliente(),
        _service.obtenerZonas(),
        _service.obtenerDepartamentos(),
        _service.obtenerMetodosPago(),
      ]);
      datosCliente = results[0] as DatosClienteModel?;
      zonas = List<ZonaModel>.from(results[1] as List);
      departamentos = List<DepartamentoModel>.from(results[2] as List);
      metodosPago = List<MetodoPagoModel>.from(results[3] as List).where((m) => m.activo).toList();
      metodosPago.sort((a, b) => a.orden.compareTo(b.orden));
      metodoSeleccionado = metodosPago.isNotEmpty ? metodosPago.first : null;
      if (datosCliente?.departamentoId != null) {
        municipios = await _service.obtenerMunicipios(datosCliente!.departamentoId!);
      }
      await _previewEnvio();
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarZona(int? zonaId) async {
    error = null;
    departamentos = <DepartamentoModel>[];
    municipios = <MunicipioModel>[];
    notifyListeners();
    try {
      if (zonaId == null) {
        departamentos = await _service.obtenerDepartamentos();
      } else {
        departamentos = await _service.obtenerDepartamentosPorZona(zonaId);
      }
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> seleccionarDepartamento(int? departamentoId) async {
    error = null;
    municipios = <MunicipioModel>[];
    notifyListeners();
    try {
      if (departamentoId != null) municipios = await _service.obtenerMunicipios(departamentoId);
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      notifyListeners();
    }
  }

  void seleccionarMetodo(MetodoPagoModel metodo) {
    metodoSeleccionado = metodo;
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
      if (datosCliente?.departamentoId != null) {
        municipios = await _service.obtenerMunicipios(datosCliente!.departamentoId!);
      }
      await _previewEnvio();
      return true;
    } catch (e) {
      error = _friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<PedidoModel?> confirmarPedido({
    required String referenciaTransferencia,
    String observacion = '',
  }) async {
    final referencia = referenciaTransferencia.trim();
    if (referencia.isEmpty) {
      error = 'Ingresá la referencia de transferencia.';
      notifyListeners();
      return null;
    }
    if (metodoSeleccionado == null) {
      error = 'Seleccioná un método de pago activo.';
      notifyListeners();
      return null;
    }
    if (requiereDatosCliente) {
      error = 'Completá tus datos de entrega antes de confirmar.';
      notifyListeners();
      return null;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      final pedido = await _service.realizarPedido(
        metodoPagoId: metodoSeleccionado!.id,
        referenciaTransferencia: referencia,
        observacion: observacion,
      );
      await CartController.instance.cargarCarrito();
      return pedido;
    } catch (e) {
      error = _friendlyError(e);
      return null;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> _previewEnvio() async {
    costoEnvio = 0;
    porcentajeEnvio = 0;
    zonaEnvio = '';
    final depId = datosCliente?.departamentoId;
    if (depId == null || subtotal <= 0) return;
    try {
      final data = await _service.previewCostoEnvio(subtotal: subtotal, departamentoId: depId);
      costoEnvio = _toDouble(data['costo_envio']);
      porcentajeEnvio = _toDouble(data['porcentaje_envio']);
      zonaEnvio = (data['zona_nombre'] ?? data['tarifa_nombre'] ?? '').toString();
    } catch (_) {
      // El preview no debe bloquear el checkout visual; el backend valida en el pedido.
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? 'No se pudo procesar la operación.' : text;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}
