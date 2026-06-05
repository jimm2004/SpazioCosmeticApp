import '../../models/producto_catalogo_model.dart';
import '../../services/catalogo_service.dart';

class CatalogoController {
  final CatalogoService _service = CatalogoService();

  Future<List<ProductoCatalogoModel>> listarProductos() async {
    final data = await _service.listarProductos();

    return data
        .where((e) => e is Map)
        .map<ProductoCatalogoModel>(
          (e) => ProductoCatalogoModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((producto) => producto.activo && producto.tieneImagen)
        .toList();
  }

  Future<ProductoCatalogoModel> obtenerProducto(int idProducto) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    final data = await _service.obtenerProducto(idProducto);

    return ProductoCatalogoModel.fromJson(data);
  }

  Future<List<ProductoCatalogoModel>> buscarProductosPorNombre(String nombre) async {
    final texto = nombre.trim();

    if (texto.isEmpty) {
      return listarProductos();
    }

    final data = await _service.buscarProductosPorNombre(texto);

    return data
        .where((e) => e is Map)
        .map<ProductoCatalogoModel>(
          (e) => ProductoCatalogoModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((producto) => producto.activo && producto.tieneImagen)
        .toList();
  }

  Future<List<Map<String, dynamic>>> listarProductosParaGrid() async {
    final productos = await listarProductos();

    productos.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    return productos.map((p) => p.toProductCardMap()).toList();
  }

  Future<List<Map<String, dynamic>>> buscarProductosParaGrid(String nombre) async {
    final productos = await buscarProductosPorNombre(nombre);

    productos.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );

    return productos.map((p) => p.toProductCardMap()).toList();
  }
}