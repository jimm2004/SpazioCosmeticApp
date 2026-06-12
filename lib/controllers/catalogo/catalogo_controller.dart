import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/catalogo/novedad_publica_model.dart';
import '../../models/catalogo/producto_catalogo_model.dart';
import '../../services/catalogo_service.dart';

class CatalogoController extends ChangeNotifier {
  final CatalogoService _service;

  CatalogoController({CatalogoService? service}) : _service = service ?? CatalogoService();

  static const Duration _inicioCacheDuration = Duration(seconds: 35);
  static const int pageSize = 24;

  bool loading = false;
  bool loadingMore = false;

  String? error;
  String? loadMoreError;

  String buscarActual = '';
  int? categoriaIdActual;

  int currentPage = 0;
  int lastPage = 1;
  int totalProductos = 0;
  bool hasMore = true;

  List<ProductoCatalogo> productos = <ProductoCatalogo>[];
  List<NovedadPublicaModel> novedades = <NovedadPublicaModel>[];
  List<Map<String, dynamic>> categoriasRaw = <Map<String, dynamic>>[];

  DateTime? _lastInicioAt;
  Future<void>? _inicioInFlight;
  Future<void>? _busquedaInFlight;
  Future<void>? _loadMoreInFlight;

  bool get puedeCargarMas => hasMore && !loading && !loadingMore;

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
  /// Ahora solo pide la primera página de productos para no saturar la vista.
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
    loadingMore = false;
    error = null;
    loadMoreError = null;
    buscarActual = '';
    categoriaIdActual = null;
    currentPage = 0;
    lastPage = 1;
    totalProductos = 0;
    hasMore = true;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _service.obtenerProductosPaginado(page: 1, perPage: pageSize),
        _service.obtenerNovedades(),
        _service.obtenerCategoriasCatalogo().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final productosResponse = results[0] as CatalogoProductosResponse;

      productos = List<ProductoCatalogo>.from(productosResponse.data);
      novedades = List<NovedadPublicaModel>.from(results[1] as List);
      categoriasRaw = List<Map<String, dynamic>>.from(results[2] as List);

      currentPage = productosResponse.currentPage;
      lastPage = productosResponse.lastPage;
      totalProductos = productosResponse.total;
      hasMore = productosResponse.hasMore;

      _lastInicioAt = DateTime.now();
      _ordenarProductosPorLinea();
    } catch (e) {
      error = _friendlyError(e);
      productos = <ProductoCatalogo>[];
      hasMore = false;
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
    loadingMore = false;
    error = null;
    loadMoreError = null;
    currentPage = 0;
    lastPage = 1;
    totalProductos = 0;
    hasMore = true;
    notifyListeners();

    try {
      final response = await _service.obtenerProductosPaginado(
        buscar: query,
        page: 1,
        perPage: pageSize,
        categoriaId: categoriaIdActual,
      );

      productos = List<ProductoCatalogo>.from(response.data);
      currentPage = response.currentPage;
      lastPage = response.lastPage;
      totalProductos = response.total;
      hasMore = response.hasMore;

      _lastInicioAt = DateTime.now();
      _ordenarProductosPorLinea();
    } catch (e) {
      error = _friendlyError(e);
      productos = <ProductoCatalogo>[];
      hasMore = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Llamar este método cuando el usuario llegue cerca del final del scroll.
  Future<void> cargarMasProductos() {
    if (_loadMoreInFlight != null) return _loadMoreInFlight!;
    if (!puedeCargarMas) return Future<void>.value();

    _loadMoreInFlight = _cargarMasProductosImpl().whenComplete(() {
      _loadMoreInFlight = null;
    });

    return _loadMoreInFlight!;
  }

  Future<void> _cargarMasProductosImpl() async {
    loadingMore = true;
    loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = currentPage <= 0 ? 1 : currentPage + 1;

      final response = await _service.obtenerProductosPaginado(
        buscar: buscarActual,
        page: nextPage,
        perPage: pageSize,
        categoriaId: categoriaIdActual,
      );

      final before = productos.length;
      _agregarProductosSinDuplicar(response.data);

      currentPage = response.currentPage;
      lastPage = response.lastPage;
      totalProductos = response.total;

      final agregadoAlgo = productos.length > before;
      hasMore = response.hasMore && agregadoAlgo;

      if (response.data.isEmpty || !agregadoAlgo) {
        hasMore = false;
      }

      _ordenarProductosPorLinea();
    } catch (e) {
      loadMoreError = _friendlyError(e);
    } finally {
      loadingMore = false;
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
    currentPage = 0;
    lastPage = 1;
    totalProductos = 0;
    hasMore = true;
    notifyListeners();
  }

  void _agregarProductosSinDuplicar(List<ProductoCatalogo> nuevos) {
    final idsExistentes = productos.map((p) => p.idProducto).toSet();

    for (final producto in nuevos) {
      if (idsExistentes.contains(producto.idProducto)) continue;
      productos.add(producto);
      idsExistentes.add(producto.idProducto);
    }
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
