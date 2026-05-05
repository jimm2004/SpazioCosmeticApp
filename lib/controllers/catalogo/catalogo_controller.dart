import 'package:flutter/foundation.dart';

import '../../models/catalogo/novedad_publica_model.dart';
import '../../models/catalogo/producto_catalogo_model.dart';
import '../../services/catalogo_service.dart';

class CatalogoController extends ChangeNotifier {
  final CatalogoService _service = CatalogoService();

  List<ProductoCatalogo> productos = [];
  List<NovedadPublicaModel> novedades = [];
  bool loading = false;
  String? error;

  Future<void> cargarInicio() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        _service.obtenerProductos(),
        _service.obtenerNovedades(),
      ]);
      productos = result[0] as List<ProductoCatalogo>;
      novedades = result[1] as List<NovedadPublicaModel>;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buscar(String query) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      productos = query.trim().isEmpty
          ? await _service.obtenerProductos()
          : await _service.buscarProductos(query.trim());
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<String> get categorias {
    final set = <String>{'Todos'};
    for (final p in productos) {
      set.add(p.categoriaNombre);
    }
    return set.toList();
  }

  Map<String, List<ProductoCatalogo>> productosPorCategoria(String filtro) {
    final source = filtro == 'Todos'
        ? productos
        : productos.where((p) => p.categoriaNombre.toLowerCase() == filtro.toLowerCase()).toList();

    final map = <String, List<ProductoCatalogo>>{};
    for (final p in source) {
      if (p.imagenPrincipal.isEmpty) continue;
      map.putIfAbsent(p.categoriaNombre, () => []);
      map[p.categoriaNombre]!.add(p);
    }
    return map;
  }
}
