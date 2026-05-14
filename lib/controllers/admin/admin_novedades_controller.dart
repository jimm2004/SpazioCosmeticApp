import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/novedad_model.dart';
import '../../models/novedad_producto_imagen_model.dart';
import '../../services/admin_novedades_service.dart';

enum AdminNovedadFiltro { todas, visibles, ocultas, conImagen, sinImagen }

String adminNovedadFiltroLabel(AdminNovedadFiltro filtro) {
  switch (filtro) {
    case AdminNovedadFiltro.todas:
      return 'Todas';
    case AdminNovedadFiltro.visibles:
      return 'Visibles';
    case AdminNovedadFiltro.ocultas:
      return 'Ocultas';
    case AdminNovedadFiltro.conImagen:
      return 'Con imagen';
    case AdminNovedadFiltro.sinImagen:
      return 'Sin imagen';
  }
}

class AdminNovedadesController extends ChangeNotifier {
  final AdminNovedadesService _service = AdminNovedadesService();

  List<NovedadModel> novedades = [];
  List<NovedadModel> filtradas = [];

  bool loading = false;
  bool saving = false;
  bool _requestInProgress = false;
  DateTime? _lastRequestAt;
  String? error;

  String query = '';
  AdminNovedadFiltro filtro = AdminNovedadFiltro.todas;

  static const Duration _minRefreshGap = Duration(seconds: 4);

  Future<void> cargarNovedades({
    bool force = false,
    bool silent = false,
  }) async {
    if (_requestInProgress) {
      if (!silent) {
        error = 'Ya hay una carga en curso. Evitamos duplicar GET.';
        notifyListeners();
      }
      return;
    }

    final now = DateTime.now();
    final diff = _lastRequestAt == null ? null : now.difference(_lastRequestAt!);
    if (!force && diff != null && diff < _minRefreshGap) {
      if (!silent) {
        final wait = _minRefreshGap.inSeconds - diff.inSeconds;
        error = 'Actualización omitida: espera ${wait}s para no saturar la API.';
        notifyListeners();
      }
      return;
    }

    _requestInProgress = true;
    _lastRequestAt = now;
    loading = true;
    error = null;
    notifyListeners();

    try {
      novedades = await _service.listarNovedadesAdmin();
      _ordenar();
      _aplicarFiltrosNotificando(false);
    } catch (e) {
      error = _cleanError(e);
    } finally {
      loading = false;
      _requestInProgress = false;
      notifyListeners();
    }
  }

  Future<void> refreshForzado() async {
    _service.limpiarCacheProductos();
    await cargarNovedades(force: true);
  }

  void setQuery(String value) {
    query = value;
    _aplicarFiltrosNotificando(true);
  }

  void limpiarBusqueda() {
    query = '';
    _aplicarFiltrosNotificando(true);
  }

  void setFiltro(AdminNovedadFiltro value) {
    filtro = value;
    _aplicarFiltrosNotificando(true);
  }

  Future<List<ProductoNovedadBusquedaModel>> buscarProductosParaNovedad(
    String nombre, {
    bool forceRefresh = false,
  }) async {
    final clean = nombre.trim();
    if (clean.length < 2) {
      throw Exception('Ingresá al menos 2 letras del producto.');
    }

    return _service.buscarProductosParaNovedad(
      clean,
      forceRefresh: forceRefresh,
    );
  }

  Future<bool> crearNovedad({
    required String titulo,
    required String descripcion,
    XFile? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
    return _runSaving(() async {
      final nueva = await _service.crearNovedad(
        titulo: titulo,
        descripcion: descripcion,
        foto: foto,
        productoImagenId: productoImagenId,
        enlaceUrl: enlaceUrl,
        activo: activo,
        orden: orden,
      );
      novedades.insert(0, nueva);
      _ordenar();
      _aplicarFiltrosNotificando(false);
      return true;
    });
  }

  Future<bool> actualizarNovedad({
    required int idNovedad,
    required String titulo,
    required String descripcion,
    XFile? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
    return _runSaving(() async {
      final actualizada = await _service.actualizarNovedad(
        idNovedad: idNovedad,
        titulo: titulo,
        descripcion: descripcion,
        foto: foto,
        productoImagenId: productoImagenId,
        enlaceUrl: enlaceUrl,
        activo: activo,
        orden: orden,
      );

      final index = novedades.indexWhere((n) => n.idNovedad == idNovedad);
      if (index >= 0) {
        novedades[index] = actualizada;
      } else {
        novedades.insert(0, actualizada);
      }

      _ordenar();
      _aplicarFiltrosNotificando(false);
      return true;
    });
  }

  Future<bool> cambiarEstado(NovedadModel novedad, bool activo) async {
    return _runSaving(() async {
      final actualizada = await _service.cambiarEstado(
        idNovedad: novedad.idNovedad,
        activo: activo,
      );

      final index = novedades.indexWhere((item) => item.idNovedad == novedad.idNovedad);
      if (index >= 0) novedades[index] = actualizada;

      _ordenar();
      _aplicarFiltrosNotificando(false);
      return true;
    });
  }

  Future<bool> eliminarNovedad(NovedadModel novedad) async {
    return _runSaving(() async {
      await _service.eliminarNovedad(novedad.idNovedad);
      novedades.removeWhere((item) => item.idNovedad == novedad.idNovedad);
      _aplicarFiltrosNotificando(false);
      return true;
    });
  }

  int countFor(AdminNovedadFiltro value) {
    switch (value) {
      case AdminNovedadFiltro.todas:
        return novedades.length;
      case AdminNovedadFiltro.visibles:
        return novedades.where((n) => n.activo).length;
      case AdminNovedadFiltro.ocultas:
        return novedades.where((n) => !n.activo).length;
      case AdminNovedadFiltro.conImagen:
        return novedades.where((n) => _hasImage(n)).length;
      case AdminNovedadFiltro.sinImagen:
        return novedades.where((n) => !_hasImage(n)).length;
    }
  }

  int get visibles => countFor(AdminNovedadFiltro.visibles);
  int get ocultas => countFor(AdminNovedadFiltro.ocultas);
  int get conImagen => countFor(AdminNovedadFiltro.conImagen);
  int get sinImagen => countFor(AdminNovedadFiltro.sinImagen);

  Future<bool> _runSaving(Future<bool> Function() action) async {
    if (saving) return false;

    saving = true;
    error = null;
    notifyListeners();

    try {
      final ok = await action();
      return ok;
    } catch (e) {
      error = _cleanError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void _aplicarFiltrosNotificando(bool notify) {
    final q = query.trim().toLowerCase();

    filtradas = novedades.where((n) {
      final textoOk = q.isEmpty ||
          n.titulo.toLowerCase().contains(q) ||
          n.descripcion.toLowerCase().contains(q) ||
          n.orden.toString().contains(q);

      if (!textoOk) return false;

      switch (filtro) {
        case AdminNovedadFiltro.todas:
          return true;
        case AdminNovedadFiltro.visibles:
          return n.activo;
        case AdminNovedadFiltro.ocultas:
          return !n.activo;
        case AdminNovedadFiltro.conImagen:
          return _hasImage(n);
        case AdminNovedadFiltro.sinImagen:
          return !_hasImage(n);
      }
    }).toList();

    if (notify) notifyListeners();
  }

  void _ordenar() {
    novedades.sort((a, b) {
      final ordenCompare = a.orden.compareTo(b.orden);
      if (ordenCompare != 0) return ordenCompare;
      return b.idNovedad.compareTo(a.idNovedad);
    });
  }

  bool _hasImage(NovedadModel n) {
    final img = n.imagenPrincipal.trim();
    return img.isNotEmpty && img.toLowerCase() != 'null';
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}
