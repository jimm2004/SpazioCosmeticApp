import 'api_service.dart';

class CatalogoService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> listarProductos() async {
    final data = await _api.get('/api/catalogo/productos');
    return data['data'] ?? [];
  }

  Future<Map<String, dynamic>> obtenerProducto(int idProducto) async {
    final data = await _api.get('/api/catalogo/productos/$idProducto');
    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  Future<List<dynamic>> buscarProductosPorNombre(String nombre) async {
    final data = await _api.get('/api/catalogo/buscar/$nombre');
    return data['data'] ?? [];
  }
}