import 'package:flutter/foundation.dart';

import '../../models/catalogo/metodo_pago_model.dart';
import '../../models/catalogo/tarifa_envio_model.dart';
import '../../services/admin_configuracion_comercial_service.dart';

class AdminConfiguracionComercialController extends ChangeNotifier {
  final AdminConfiguracionComercialService _service = AdminConfiguracionComercialService();

  List<MetodoPagoModel> metodos = [];
  List<TarifaEnvioModel> tarifas = [];
  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> cargarTodo() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _service.listarMetodosPago(),
        _service.listarTarifasEnvio(),
      ]);
      metodos = result[0] as List<MetodoPagoModel>;
      tarifas = result[1] as List<TarifaEnvioModel>;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarMetodo({
    int? id,
    required String banco,
    required String moneda,
    required String titular,
    required String numeroCuenta,
    String descripcion = '',
    int orden = 1,
    bool activo = true,
  }) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final metodo = await _service.guardarMetodoPago(
        id: id,
        banco: banco,
        moneda: moneda,
        titular: titular,
        numeroCuenta: numeroCuenta,
        descripcion: descripcion,
        orden: orden,
        activo: activo,
      );
      final index = metodos.indexWhere((m) => m.id == metodo.id);
      if (index >= 0) {
        metodos[index] = metodo;
      } else {
        metodos.add(metodo);
      }
      metodos.sort((a, b) => a.orden.compareTo(b.orden));
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstadoMetodo(MetodoPagoModel metodo, bool activo) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final nuevo = await _service.cambiarEstadoMetodoPago(metodo.id, activo);
      final index = metodos.indexWhere((m) => m.id == metodo.id);
      if (index >= 0) metodos[index] = nuevo;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarTarifa(TarifaEnvioModel tarifa, double porcentaje, bool activo, String descripcion) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final nueva = await _service.actualizarTarifaEnvio(id: tarifa.id, porcentajeEnvio: porcentaje, activo: activo, descripcion: descripcion);
      final index = tarifas.indexWhere((t) => t.id == tarifa.id);
      if (index >= 0) tarifas[index] = nueva;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
