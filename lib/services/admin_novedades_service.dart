import 'dart:io';

import '../models/novedad_model.dart';
import '../models/novedad_producto_imagen_model.dart';
import 'api_service.dart';

class AdminNovedadesService {
  final ApiService _api = ApiService();

  Future<List<NovedadModel>> listarNovedadesAdmin() async {
    final response = await _api.get('/api/admin/novedades');

    return _parseList(response)
        .map((item) => NovedadModel.fromJson(item))
        .toList();
  }

  Future<NovedadModel> detalleNovedad(int idNovedad) async {
    final response = await _api.get('/api/admin/novedades/$idNovedad');

    return NovedadModel.fromJson(_parseData(response));
  }

  Future<List<ProductoNovedadBusquedaModel>> buscarProductosParaNovedad(
    String nombre,
  ) async {
    final query = nombre.trim().toLowerCase();

    if (query.length < 2) {
      throw Exception('Ingresá al menos 2 letras del nombre del producto.');
    }

    final response = await _api.get('/api/admin/productos');

    final productos = _parseList(response)
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
      throw Exception('No encontré productos con ese nombre o no tienen imágenes.');
    }

    return productos;
  }

  Future<NovedadModel> crearNovedad({
    required String titulo,
    required String descripcion,
    File? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
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
    File? foto,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) async {
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
    final response = await _api.post(
      '/api/admin/novedades/$idNovedad/estado',
      body: {
        'activo': activo ? 1 : 0,
      },
    );

    return NovedadModel.fromJson(_parseData(response));
  }

  Future<void> eliminarNovedad(int idNovedad) async {
    await _api.delete('/api/admin/novedades/$idNovedad');
  }

  Map<String, dynamic> _toBody({
    required String titulo,
    required String descripcion,
    int? productoImagenId,
    String? enlaceUrl,
    required bool activo,
    required int orden,
  }) {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'producto_imagen_id': productoImagenId,
      'enlace_url': enlaceUrl,
      'activo': activo ? 1 : 0,
      'orden': orden,
    };
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
      'titulo': titulo,
      'descripcion': descripcion,
      'activo': activo ? '1' : '0',
      'orden': orden.toString(),
    };

    if (productoImagenId != null) {
      fields['producto_imagen_id'] = productoImagenId.toString();
    }

    if (enlaceUrl != null && enlaceUrl.trim().isNotEmpty) {
      fields['enlace_url'] = enlaceUrl.trim();
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
