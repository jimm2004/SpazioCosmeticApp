import 'dart:io';

import '../../models/producto_admin_model.dart';
import '../../services/admin_productos_service.dart';

class AdminProductosController {
  final AdminProductosService _service = AdminProductosService();

  Future<List<ProductoAdminModel>> obtenerProductos() async {
    final data = await _service.obtenerProductosAdmin();

    return data
        .where((e) => e is Map)
        .map<ProductoAdminModel>(
          (e) => ProductoAdminModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<ProductoAdminModel> obtenerDetalleProducto(int idProducto) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    final data = await _service.obtenerDetalleProducto(idProducto);

    return ProductoAdminModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<String> subirImagenProducto({
    required int idProducto,
    required File imagen,
    double? precioFinal,
    bool? esPrincipal,
  }) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    if (!await imagen.exists()) {
      throw Exception('La imagen seleccionada no existe en el dispositivo.');
    }

    if (precioFinal != null && precioFinal < 0) {
      throw Exception('El precio final no puede ser negativo.');
    }

    final data = await _service.subirImagenProducto(
      idProducto: idProducto,
      imagen: imagen,
      precioFinal: precioFinal,
      esPrincipal: esPrincipal,
    );

    return data['message']?.toString() ?? 'Imagen guardada correctamente.';
  }

  Future<String> cambiarImagenProducto({
    required int imagenId,
    required File imagen,
    double? precioFinal,
    bool? esPrincipal,
  }) async {
    if (imagenId <= 0) {
      throw Exception('ID de imagen inválido.');
    }

    if (!await imagen.exists()) {
      throw Exception('La imagen seleccionada no existe en el dispositivo.');
    }

    if (precioFinal != null && precioFinal < 0) {
      throw Exception('El precio final no puede ser negativo.');
    }

    final data = await _service.cambiarImagenProducto(
      imagenId: imagenId,
      imagen: imagen,
      precioFinal: precioFinal,
      esPrincipal: esPrincipal,
    );

    return data['message']?.toString() ?? 'Imagen reemplazada correctamente.';
  }

  Future<String> actualizarPrecioFinalImagen({
    required int imagenId,
    required double precioFinal,
  }) async {
    if (imagenId <= 0) {
      throw Exception('ID de imagen inválido.');
    }

    if (precioFinal < 0) {
      throw Exception('El precio final no puede ser negativo.');
    }

    final data = await _service.actualizarPrecioFinalImagen(
      imagenId: imagenId,
      precioFinal: precioFinal,
    );

    return data['message']?.toString() ??
        'Precio final actualizado correctamente.';
  }

  Future<String> cambiarVisibilidadProducto({
    required int idProducto,
    required bool esVisible,
  }) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    return await _service.cambiarEstadoProducto(
      idProducto: idProducto,
      activo: esVisible,
    );
  }
}