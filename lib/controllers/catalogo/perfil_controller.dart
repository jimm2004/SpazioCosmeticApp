import 'package:flutter/foundation.dart';

import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/perfil_usuario_model.dart';
import '../../models/catalogo/ubicacion_model.dart';
import '../../services/catalogo_service.dart';

class PerfilController extends ChangeNotifier {
  final CatalogoService _service;

  PerfilController({CatalogoService? service}) : _service = service ?? CatalogoService();

  bool loading = false;
  bool saving = false;
  String? error;

  PerfilUsuarioModel? usuario;
  DatosClienteModel? datosCliente;
  List<ZonaModel> zonas = <ZonaModel>[];
  List<DepartamentoModel> departamentos = <DepartamentoModel>[];
  List<MunicipioModel> municipios = <MunicipioModel>[];

  Future<void> cargar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _service.obtenerMiPerfil(),
        _service.obtenerDatosCliente(),
        _service.obtenerZonas(),
        _service.obtenerDepartamentos(),
      ]);
      usuario = results[0] as PerfilUsuarioModel;
      datosCliente = results[1] as DatosClienteModel?;
      zonas = List<ZonaModel>.from(results[2] as List);
      departamentos = List<DepartamentoModel>.from(results[3] as List);
      if (datosCliente?.departamentoId != null) {
        municipios = await _service.obtenerMunicipios(datosCliente!.departamentoId!);
      }
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarZona(int? zonaId) async {
    departamentos = <DepartamentoModel>[];
    municipios = <MunicipioModel>[];
    error = null;
    notifyListeners();
    try {
      departamentos = zonaId == null ? await _service.obtenerDepartamentos() : await _service.obtenerDepartamentosPorZona(zonaId);
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> seleccionarDepartamento(int? departamentoId) async {
    municipios = <MunicipioModel>[];
    error = null;
    notifyListeners();
    try {
      if (departamentoId != null) municipios = await _service.obtenerMunicipios(departamentoId);
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      notifyListeners();
    }
  }

  Future<bool> guardar(DatosClienteModel datos) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      datosCliente = datosCliente == null ? await _service.guardarDatosCliente(datos) : await _service.actualizarDatosCliente(datos);
      if (datosCliente?.departamentoId != null) municipios = await _service.obtenerMunicipios(datosCliente!.departamentoId!);
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
    return text.isEmpty ? 'No se pudo cargar el perfil.' : text;
  }
}
