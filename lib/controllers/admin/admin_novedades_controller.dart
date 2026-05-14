import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/novedad_model.dart';
import '../../models/novedad_producto_imagen_model.dart';
import '../../services/admin_novedades_service.dart';

class AdminNovedadesController extends ChangeNotifier {
  final AdminNovedadesService _service = AdminNovedadesService();

  List<NovedadModel> novedades = [];

  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> cargarNovedades() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      novedades = await _service.listarNovedadesAdmin();
      _ordenar();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<ProductoNovedadBusquedaModel>> buscarProductosParaNovedad(
    String nombre,
  ) async {
    final query = nombre.trim();

    if (query.length < 2) {
      throw Exception('Ingresá al menos 2 letras del producto.');
    }

    return _service.buscarProductosParaNovedad(query);
  }

  Future<bool> crearNovedad({
    required String titulo,
    required String descripcion,
    File? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
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
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarNovedad({
    required int idNovedad,
    required String titulo,
    required String descripcion,
    File? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
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
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstado(NovedadModel novedad, bool activo) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
      final actualizada = await _service.cambiarEstado(
        idNovedad: novedad.idNovedad,
        activo: activo,
      );

      final index = novedades.indexWhere(
        (item) => item.idNovedad == novedad.idNovedad,
      );

      if (index >= 0) {
        novedades[index] = actualizada;
      }

      _ordenar();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarNovedad(NovedadModel novedad) async {
    saving = true;
    error = null;
    notifyListeners();

    try {
      await _service.eliminarNovedad(novedad.idNovedad);
      novedades.removeWhere((item) => item.idNovedad == novedad.idNovedad);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void _ordenar() {
    novedades.sort((a, b) {
      final ordenCompare = a.orden.compareTo(b.orden);
      if (ordenCompare != 0) return ordenCompare;

      return b.idNovedad.compareTo(a.idNovedad);
    });
  }
}
