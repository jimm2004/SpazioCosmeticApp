import 'dart:io';
import '../../models/producto_admin_model.dart';
import '../../services/api_service.dart';

class AdminProductosController {
  final ApiService _apiService = ApiService();

  Future<List<ProductoAdminModel>> obtenerProductos() async {
    final data = await _apiService.obtenerProductosAdmin();
    return data
        .map<ProductoAdminModel>((e) => ProductoAdminModel.fromJson(e))
        .toList();
  }

  Future<ProductoAdminModel> obtenerDetalleProducto(int idProducto) async {
    final data = await _apiService.obtenerDetalleProducto(idProducto);
    return ProductoAdminModel.fromJson(data);
  }

  Future<String> subirImagenProducto({
    required int idProducto,
    required File imagen,
  }) async {
    return await _apiService.subirImagenProducto(
      idProducto: idProducto,
      imagen: imagen,
    );
  }

  // MÉTODO CONECTADO A LA API REAL
  Future<String> cambiarVisibilidadProducto({
    required int idProducto,
    required bool esVisible,
  }) async {
    // Aquí llamamos al método real de tu ApiService
    return await _apiService.cambiarEstadoProducto(
      idProducto: idProducto, 
      activo: esVisible,
    );
  }
}