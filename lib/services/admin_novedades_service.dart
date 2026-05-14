import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/novedad_model.dart';
import '../models/novedad_producto_imagen_model.dart';
import 'api_service.dart';

class AdminNovedadesService {
  final ApiService _api = ApiService();

  static const Duration _productosCacheDuration = Duration(seconds: 20);

  List<Map<String, dynamic>>? _productosCache;
  DateTime? _productosCacheAt;

  Future<List<NovedadModel>> listarNovedadesAdmin() async {
    final response = await _api.get('/api/admin/novedades');

    return _parseList(response)
        .map((item) => NovedadModel.fromJson(item))
        .toList();
  }

  Future<NovedadModel> detalleNovedad(int idNovedad) async {
    if (idNovedad <= 0) {
      throw Exception('ID de novedad inválido.');
    }

    final response = await _api.get('/api/admin/novedades/$idNovedad');

    return NovedadModel.fromJson(_parseData(response));
  }

  Future<List<ProductoNovedadBusquedaModel>> buscarProductosParaNovedad(
    String nombre, {
    bool forceRefresh = false,
  }) async {
    final query = nombre.trim().toLowerCase();

    if (query.length < 2) {
      throw Exception('Ingresá al menos 2 letras del nombre del producto.');
    }

    final productosRaw = await _obtenerProductosCacheados(
      forceRefresh: forceRefresh,
    );

    final productos = productosRaw
        .map((item) => ProductoNovedadBusquedaModel.fromJson(item))
        .where((producto) {
          final nombreProducto = producto.nombre.toLowerCase();
          return producto.idProducto > 0 &&
              nombreProducto.contains(query) &&
              producto.imagenes.isNotEmpty;
        })
        .toList();

    productos.sort((a, b) => a.nombre.compareTo(b.nombre));

    if (productos.isEmpty) {
      throw Exception(
        'No encontré productos con ese nombre o no tienen imágenes.',
      );
    }

    return productos;
  }

  Future<NovedadModel> crearNovedad({
    required String titulo,
    required String descripcion,
    XFile? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
    _validarPayload(
      titulo: titulo,
      descripcion: descripcion,
      orden: orden,
      productoImagenId: productoImagenId,
      enlaceUrl: enlaceUrl,
    );

    final response = foto != null
        ? await _api.multipartPost(
            '/api/admin/novedades',
            fileField: 'foto',
            file: foto,
            fields: _toMultipartFields(
              titulo: titulo,
              descripcion: descripcion,
              productoImagenId: productoImagenId,
              enlaceUrl: enlaceUrl,
              activo: activo,
              orden: orden,
            ),
          )
        : await _api.post(
            '/api/admin/novedades',
            body: _toBody(
              titulo: titulo,
              descripcion: descripcion,
              productoImagenId: productoImagenId,
              enlaceUrl: enlaceUrl,
              activo: activo,
              orden: orden,
            ),
          );

    return NovedadModel.fromJson(_parseData(response));
  }

  Future<NovedadModel> actualizarNovedad({
    required int idNovedad,
    required String titulo,
    required String descripcion,
    XFile? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
    if (idNovedad <= 0) {
      throw Exception('ID de novedad inválido.');
    }

    _validarPayload(
      titulo: titulo,
      descripcion: descripcion,
      orden: orden,
      productoImagenId: productoImagenId,
      enlaceUrl: enlaceUrl,
    );

    final response = foto != null
        ? await _api.multipartPost(
            '/api/admin/novedades/$idNovedad',
            fileField: 'foto',
            file: foto,
            fields: _toMultipartFields(
              titulo: titulo,
              descripcion: descripcion,
              productoImagenId: productoImagenId,
              enlaceUrl: enlaceUrl,
              activo: activo,
              orden: orden,
            ),
          )
        : await _api.post(
            '/api/admin/novedades/$idNovedad',
            body: _toBody(
              titulo: titulo,
              descripcion: descripcion,
              productoImagenId: productoImagenId,
              enlaceUrl: enlaceUrl,
              activo: activo,
              orden: orden,
            ),
          );

    return NovedadModel.fromJson(_parseData(response));
  }

  Future<NovedadModel> cambiarEstado({
    required int idNovedad,
    required bool activo,
  }) async {
    if (idNovedad <= 0) {
      throw Exception('ID de novedad inválido.');
    }

    final response = await _api.post(
      '/api/admin/novedades/$idNovedad/estado',
      body: {
        'activo': activo ? 1 : 0,
      },
    );

    return NovedadModel.fromJson(_parseData(response));
  }

  Future<void> eliminarNovedad(int idNovedad) async {
    if (idNovedad <= 0) {
      throw Exception('ID de novedad inválido.');
    }

    await _api.delete('/api/admin/novedades/$idNovedad');
  }

  void limpiarCacheProductos() {
    _productosCache = null;
    _productosCacheAt = null;
  }

  Future<List<Map<String, dynamic>>> _obtenerProductosCacheados({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final cacheVigente = _productosCache != null &&
        _productosCacheAt != null &&
        now.difference(_productosCacheAt!) < _productosCacheDuration;

    if (!forceRefresh && cacheVigente) {
      return _productosCache!;
    }

    final response = await _api.get('/api/admin/productos');
    final productos = _parseList(response);

    _productosCache = productos;
    _productosCacheAt = now;

    debugPrint(
      'AdminNovedadesService: productos cargados para novedades (${productos.length}).',
    );

    return productos;
  }

  void _validarPayload({
    required String titulo,
    required String descripcion,
    required int orden,
    int? productoImagenId,
    String? enlaceUrl,
  }) {
    if (titulo.trim().isEmpty) {
      throw Exception('El título de la novedad es obligatorio.');
    }

    if (descripcion.trim().isEmpty) {
      throw Exception('La descripción de la novedad es obligatoria.');
    }

    if (orden < 0) {
      throw Exception('El orden no puede ser negativo.');
    }

    if (productoImagenId != null && productoImagenId <= 0) {
      throw Exception('La imagen de producto seleccionada no es válida.');
    }

    final cleanUrl = enlaceUrl?.trim() ?? '';
    final tieneUrl = cleanUrl.isNotEmpty;

    if (tieneUrl) {
      final uri = Uri.tryParse(cleanUrl);
      final isHttp = uri != null && (uri.isScheme('http') || uri.isScheme('https'));

      if (!isHttp) {
        throw Exception('El enlace debe iniciar con http:// o https://.');
      }
    }
  }

  Map<String, dynamic> _toBody({
    required String titulo,
    required String descripcion,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) {
    final body = <String, dynamic>{
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'activo': activo ? 1 : 0,
      'orden': orden,
    };

    if (productoImagenId != null) {
      body['producto_imagen_id'] = productoImagenId;
    }

    final cleanUrl = enlaceUrl?.trim() ?? '';
    if (cleanUrl.isNotEmpty) {
      body['enlace_url'] = cleanUrl;
    }

    return body;
  }

  Map<String, String> _toMultipartFields({
    required String titulo,
    required String descripcion,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) {
    final fields = <String, String>{
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'activo': activo ? '1' : '0',
      'orden': orden.toString(),
    };

    if (productoImagenId != null) {
      fields['producto_imagen_id'] = productoImagenId.toString();
    }

    final cleanUrl = enlaceUrl?.trim() ?? '';
    if (cleanUrl.isNotEmpty) {
      fields['enlace_url'] = cleanUrl;
    }

    return fields;
  }

  Map<String, dynamic> _parseData(dynamic response) {
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);

      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data']);
      }

      if (map['novedad'] is Map) {
        return Map<String, dynamic>.from(map['novedad']);
      }

      return map;
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _parseList(dynamic response) {
    dynamic data = response;

    if (response is Map && response['data'] != null) {
      data = response['data'];
    }

    if (response is Map && response['novedades'] != null) {
      data = response['novedades'];
    }

    if (data is! List) {
      return <Map<String, dynamic>>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
