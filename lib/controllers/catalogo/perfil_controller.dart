import 'package:flutter/foundation.dart';

import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/perfil_usuario_model.dart';
import '../../models/catalogo/ubicacion_model.dart';
import '../../services/catalogo_service.dart';

class PerfilController extends ChangeNotifier {
  final CatalogoService _service = CatalogoService();

  PerfilUsuarioModel? usuario;
  DatosClienteModel? datosCliente;
  List<ZonaModel> zonas = [];
  List<DepartamentoModel> departamentos = [];
  List<MunicipioModel> municipios = [];

  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> cargar() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.obtenerMiPerfil(),
        _service.obtenerDatosCliente(),
        _service.obtenerZonas(),
      ]);
      usuario = results[0] as PerfilUsuarioModel;
      datosCliente = results[1] as DatosClienteModel?;
      zonas = results[2] as List<ZonaModel>;

      final zonaId = datosCliente?.zonaId;
      if (zonaId != null) {
        departamentos = await _service.obtenerDepartamentosPorZona(zonaId);
      } else {
        departamentos = await _service.obtenerDepartamentos();
      }

      final departamentoId = datosCliente?.departamentoId;
      if (departamentoId != null) {
        municipios = await _service.obtenerMunicipios(departamentoId);
      }
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> seleccionarZona(int? zonaId) async {
    departamentos = [];
    municipios = [];
    datosCliente = (datosCliente ?? DatosClienteModel.empty(nombres: usuario?.name ?? '')).copyWith(
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
    notifyListeners();
  }

  Future<void> seleccionarDepartamento(int? departamentoId) async {
    municipios = [];
    datosCliente = (datosCliente ?? DatosClienteModel.empty(nombres: usuario?.name ?? '')).copyWith(
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
    notifyListeners();
  }

  Future<bool> guardar(DatosClienteModel datos) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      datosCliente = datosCliente == null
          ? await _service.guardarDatosCliente(datos)
          : await _service.actualizarDatosCliente(datos);
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
