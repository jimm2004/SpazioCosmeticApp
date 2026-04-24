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
    return data['data'] ?? {};
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