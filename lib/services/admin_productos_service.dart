import 'dart:io';

import 'api_service.dart';

class AdminProductosService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> obtenerProductosAdmin() async {
    final data = await _api.get('/api/admin/productos');
    return data['data'] ?? [];
  }

  Future<Map<String, dynamic>> obtenerDetalleProducto(int idProducto) async {
    final data = await _api.get('/api/admin/productos/$idProducto');

    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  Future<Map<String, dynamic>> subirImagenProducto({
    required int idProducto,
    required File imagen,
    double? precioFinal,
    bool? esPrincipal,
  }) async {
    final fields = <String, String>{};

    if (precioFinal != null) {
      fields['precio_final'] = precioFinal.toString();
    }

    if (esPrincipal != null) {
      fields['es_principal'] = esPrincipal ? '1' : '0';
    }

    return await _api.multipartPost(
      '/api/admin/productos/$idProducto/imagen',
      fileField: 'imagen',
      file: imagen,
      fields: fields,
    );
  }

  Future<Map<String, dynamic>> cambiarImagenProducto({
    required int imagenId,
    required File imagen,
    double? precioFinal,
    bool? esPrincipal,
  }) async {
    final fields = <String, String>{};

    if (precioFinal != null) {
      fields['precio_final'] = precioFinal.toString();
    }

    if (esPrincipal != null) {
      fields['es_principal'] = esPrincipal ? '1' : '0';
    }

    return await _api.multipartPost(
      '/api/admin/productos/imagenes/$imagenId/cambiar-imagen',
      fileField: 'imagen',
      file: imagen,
      fields: fields,
    );
  }

  Future<Map<String, dynamic>> actualizarPrecioFinalImagen({
    required int imagenId,
    required double precioFinal,
  }) async {
    return await _api.put(
      '/api/admin/productos/imagenes/$imagenId/precio-final',
      body: {
        'precio_final': precioFinal,
      },
    );
  }

  Future<String> cambiarEstadoProducto({
    required int idProducto,
    required bool activo,
  }) async {
    final data = await _api.post(
      '/api/admin/productos/$idProducto/visibilidad',
      body: {
        'activo': activo,
      },
    );

    return data['message']?.toString() ??
        (activo
            ? 'Producto visible en el catálogo'
            : 'Producto oculto exitosamente');
  }
}