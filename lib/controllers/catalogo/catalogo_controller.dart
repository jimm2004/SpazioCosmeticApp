import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/catalogo/novedad_publica_model.dart';
import '../../models/catalogo/producto_catalogo_model.dart';
import '../../services/catalogo_service.dart';

class CatalogoController extends ChangeNotifier {
  final CatalogoService _service;

  CatalogoController({CatalogoService? service}) : _service = service ?? CatalogoService();

  static const Duration _inicioCacheDuration = Duration(seconds: 35);
  static const int _limiteProductosInicio = 200;

  bool loading = false;
  String? error;
  String buscarActual = '';

  List<ProductoCatalogo> productos = <ProductoCatalogo>[];
  List<NovedadPublicaModel> novedades = <NovedadPublicaModel>[];
  List<Map<String, dynamic>> categoriasRaw = <Map<String, dynamic>>[];

  DateTime? _lastInicioAt;
  Future<void>? _inicioInFlight;
  Future<void>? _busquedaInFlight;

  bool get _cacheInicioVigente {
    if (_lastInicioAt == null || productos.isEmpty) return false;
    return DateTime.now().difference(_lastInicioAt!) < _inicioCacheDuration;
  }

  List<String> get categorias {
    final nombres = <String>[];
    for (final c in categoriasRaw) {
      final nombre = (c['nombre_categoria'] ?? c['nombre'] ?? c['linea'] ?? '').toString().trim();
      if (nombre.isNotEmpty && !nombres.contains(nombre)) nombres.add(nombre);
    }
    for (final p in productos) {
      final nombre = p.categoriaNombre.trim();
      if (nombre.isNotEmpty && !nombres.contains(nombre)) nombres.add(nombre);
    }
    return <String>['Todos', ...nombres];
  }

  /// Carga inicial con cache corto y bloqueo anti-doble GET.
  /// Esto evita que web/móvil/desktop disparen múltiples consultas si se reconstruye la pantalla.
  Future<void> cargarInicio({bool forceRefresh = false}) {
    if (_inicioInFlight != null) return _inicioInFlight!;

    if (!forceRefresh && _cacheInicioVigente) {
      error = null;
      notifyListeners();
      return Future<void>.value();
    }

    _inicioInFlight = _cargarInicioImpl(forceRefresh: forceRefresh).whenComplete(() {
      _inicioInFlight = null;
    });

    return _inicioInFlight!;
  }

  Future<void> _cargarInicioImpl({required bool forceRefresh}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _service.obtenerProductos(limite: _limiteProductosInicio),
        _service.obtenerNovedades(),
        _service.obtenerCategoriasCatalogo().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      productos = List<ProductoCatalogo>.from(results[0] as List);
      novedades = List<NovedadPublicaModel>.from(results[1] as List);
      categoriasRaw = List<Map<String, dynamic>>.from(results[2] as List);
      buscarActual = '';
      _lastInicioAt = DateTime.now();
      _ordenarProductosPorLinea();
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buscar(String texto) {
    final query = texto.trim();

    if (_busquedaInFlight != null && query == buscarActual) {
      return _busquedaInFlight!;
    }

    buscarActual = query;
    _busquedaInFlight = _buscarImpl(query).whenComplete(() {
      _busquedaInFlight = null;
    });

    return _busquedaInFlight!;
  }

  Future<void> _buscarImpl(String query) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      productos = query.isEmpty
          ? await _service.obtenerProductos(limite: _limiteProductosInicio)
          : await _service.buscarProductos(query);
      _lastInicioAt = DateTime.now();
      _ordenarProductosPorLinea();
    } catch (e) {
      error = _friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Map<String, List<ProductoCatalogo>> productosPorCategoria(String categoria) {
    final filtrados = categoria == 'Todos'
        ? productos
        : productos.where((p) => p.categoriaNombre.toLowerCase() == categoria.toLowerCase()).toList();

    final grouped = <String, List<ProductoCatalogo>>{};
    for (final producto in filtrados) {
      final key = producto.categoriaNombre.trim().isEmpty ? 'Sin línea' : producto.categoriaNombre.trim();
      grouped.putIfAbsent(key, () => <ProductoCatalogo>[]).add(producto);
    }

    final ordered = <String, List<ProductoCatalogo>>{};
    for (final nombre in categorias.skip(1)) {
      if (grouped.containsKey(nombre)) ordered[nombre] = grouped[nombre]!;
    }
    for (final entry in grouped.entries) {
      ordered.putIfAbsent(entry.key, () => entry.value);
    }
    return ordered;
  }

  void limpiarCache() {
    _lastInicioAt = null;
    productos = <ProductoCatalogo>[];
    novedades = <NovedadPublicaModel>[];
    categoriasRaw = <Map<String, dynamic>>[];
    notifyListeners();
  }

  void _ordenarProductosPorLinea() {
    productos.sort((a, b) {
      final c = a.categoriaNombre.toLowerCase().compareTo(b.categoriaNombre.toLowerCase());
      if (c != 0) return c;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  }

  String _friendlyError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? 'No se pudo cargar el catálogo.' : text;
  }
}
