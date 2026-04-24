import 'dart:io';

import '../../models/producto_admin_model.dart';
import '../../services/admin_productos_service.dart';

class AdminProductosController {
  final AdminProductosService _service = AdminProductosService();

  Future<List<ProductoAdminModel>> obtenerProductos() async {
    final data = await _service.obtenerProductosAdmin();

    return data
        .map<ProductoAdminModel>(
          (e) => ProductoAdminModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<ProductoAdminModel> obtenerDetalleProducto(int idProducto) async {
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
    final data = await _service.subirImagenProducto(
      idProducto: idProducto,
      imagen: imagen,
      precioFinal: precioFinal,
      esPrincipal: esPrincipal,
    );

    return data['message']?.toString() ?? 'Imagen guardada correctamente';
  }

  Future<String> cambiarVisibilidadProducto({
    required int idProducto,
    required bool esVisible,
  }) async {
    return await _service.cambiarEstadoProducto(
      idProducto: idProducto,
      activo: esVisible,
    );
  }
}