import '../models/catalogo/carrito_model.dart';
import '../models/catalogo/datos_cliente_model.dart';
import '../models/catalogo/metodo_pago_model.dart';
import '../models/catalogo/novedad_publica_model.dart';
import '../models/catalogo/pedido_model.dart';
import '../models/catalogo/perfil_usuario_model.dart';
import '../models/catalogo/producto_catalogo_model.dart';
import '../models/catalogo/tarifa_envio_model.dart';
import '../models/catalogo/ubicacion_model.dart';
import 'api_service.dart';

class CatalogoService {
  final ApiService _api = ApiService();

  /* --------------------------------------------------------------------------
   * PERFIL
   * -------------------------------------------------------------------------- */

  Future<PerfilUsuarioModel> obtenerMiPerfil() async {
    final response = await _api.get('/api/me');
    return PerfilUsuarioModel.fromJson(_asMap(response));
  }

  /* --------------------------------------------------------------------------
   * CATÁLOGO
   * -------------------------------------------------------------------------- */

  Future<List<ProductoCatalogo>> obtenerProductos({String buscar = '', int limite = 200, int? categoriaId}) async {
    final query = <String, dynamic>{'limite': limite};
    if (buscar.trim().isNotEmpty) query['buscar'] = buscar.trim();
    if (categoriaId != null && categoriaId > 0) query['id_categoria'] = categoriaId;
    final response = await _api.get(_withQuery('/api/catalogo/productos', query));
    return _parseList(response).map(ProductoCatalogo.fromJson).toList();
  }

  Future<List<ProductoCatalogo>> buscarProductos(String nombre) async {
    final text = nombre.trim();
    if (text.isEmpty) return obtenerProductos();
    final response = await _api.get('/api/catalogo/buscar/${Uri.encodeComponent(text)}');
    return _parseList(response).map(ProductoCatalogo.fromJson).toList();
  }


  Future<List<Map<String, dynamic>>> obtenerCategoriasCatalogo() async {
    final response = await _api.get('/api/catalogo/categorias');
    return _parseList(response);
  }

  Future<List<NovedadPublicaModel>> obtenerNovedades() async {
    final response = await _api.get('/api/catalogo/novedades');
    return _parseList(response).map(NovedadPublicaModel.fromJson).toList();
  }

  /* --------------------------------------------------------------------------
   * UBICACIÓN / ZONA / ENVÍO
   * -------------------------------------------------------------------------- */

  Future<List<ZonaModel>> obtenerZonas() async {
    final response = await _api.get('/api/catalogo/zonas');
    return _parseList(response).map(ZonaModel.fromJson).toList();
  }

  Future<List<DepartamentoModel>> obtenerDepartamentos() async {
    final response = await _api.get('/api/catalogo/departamentos');
    return _parseList(response).map(DepartamentoModel.fromJson).toList();
  }

  Future<List<DepartamentoModel>> obtenerDepartamentosPorZona(int zonaId) async {
    final response = await _api.get('/api/catalogo/zonas/$zonaId/departamentos');
    return _parseList(response).map(DepartamentoModel.fromJson).toList();
  }

  Future<List<MunicipioModel>> obtenerMunicipios(int departamentoId) async {
    final response = await _api.get('/api/catalogo/departamentos/$departamentoId/municipios');
    return _parseList(response).map(MunicipioModel.fromJson).toList();
  }

  Future<List<MetodoPagoModel>> obtenerMetodosPago() async {
    final response = await _api.get('/api/catalogo/metodos-pago');
    return _parseList(response).map(MetodoPagoModel.fromJson).toList();
  }

  Future<List<TarifaEnvioModel>> obtenerTarifasEnvio() async {
    final response = await _api.get('/api/catalogo/tarifas-envio');
    return _parseList(response).map(TarifaEnvioModel.fromJson).toList();
  }

  Future<Map<String, dynamic>> previewCostoEnvio({
    required double subtotal,
    required int departamentoId,
  }) async {
    final response = await _api.post(
      '/api/catalogo/preview-envio',
      body: {
        'subtotal': subtotal,
        'departamento_id': departamentoId,
      },
    );
    return _parseData(response);
  }

  /* --------------------------------------------------------------------------
   * DATOS DEL CLIENTE / MI PERFIL
   * -------------------------------------------------------------------------- */

  Future<DatosClienteModel?> obtenerDatosCliente() async {
    final response = await _api.get('/api/cliente/datos');
    final data = _parseNullableData(response);
    if (data == null || data.isEmpty) return null;
    return DatosClienteModel.fromJson(data);
  }

  Future<DatosClienteModel> guardarDatosCliente(DatosClienteModel datos) async {
    final response = await _api.post('/api/cliente/datos', body: datos.toJson());
    return DatosClienteModel.fromJson(_parseData(response));
  }

  Future<DatosClienteModel> actualizarDatosCliente(DatosClienteModel datos) async {
    final response = await _api.put('/api/cliente/datos', body: datos.toJson());
    return DatosClienteModel.fromJson(_parseData(response));
  }

  /* --------------------------------------------------------------------------
   * CARRITO
   * -------------------------------------------------------------------------- */

  Future<CarritoModel> verCarrito() async {
    final response = await _api.get('/api/carrito');
    return CarritoModel.fromJson(_asMap(response));
  }

  Future<CarritoModel> agregarAlCarrito({
    required int productoMasterId,
    int? productoImagenId,
    required int cantidad,
  }) async {
    final response = await _api.post(
      '/api/carrito/agregar',
      body: {
        'producto_master_id': productoMasterId,
        'producto_imagen_id': productoImagenId,
        'cantidad': cantidad,
      },
    );
    return CarritoModel.fromJson(_asMap(response));
  }

  Future<CarritoModel> editarItemCarrito({required int detalleId, required int cantidad}) async {
    final response = await _api.put('/api/carrito/items/$detalleId', body: {'cantidad': cantidad});
    return CarritoModel.fromJson(_asMap(response));
  }

  Future<CarritoModel> quitarItemCarrito(int detalleId) async {
    final response = await _api.delete('/api/carrito/items/$detalleId');
    return CarritoModel.fromJson(_asMap(response));
  }

  Future<CarritoModel> vaciarCarrito() async {
    final response = await _api.delete('/api/carrito/vaciar');
    return CarritoModel.fromJson(_asMap(response));
  }

  /* --------------------------------------------------------------------------
   * PEDIDOS
   * -------------------------------------------------------------------------- */

  Future<PedidoModel> realizarPedido({
    required int metodoPagoId,
    required String referenciaTransferencia,
    String observacion = '',
  }) async {
    final response = await _api.post(
      '/api/pedidos/realizar',
      body: {
        'metodo_pago_id': metodoPagoId,
        'referencia_transferencia': referenciaTransferencia.trim(),
        'observacion': observacion.trim(),
      },
    );
    return PedidoModel.fromJson(_parseData(response));
  }

  Future<List<PedidoModel>> listarPedidos() async {
    final response = await _api.get('/api/pedidos');
    return _parseList(response).map(PedidoModel.fromJson).toList();
  }

  Future<PedidoModel> verPedido(int id) async {
    final response = await _api.get('/api/pedidos/$id');
    return PedidoModel.fromJson(_parseData(response));
  }

  Future<List<PedidoHistorialModel>> historialPedido(int id) async {
    final response = await _api.get('/api/pedidos/$id/historial');
    return _parseList(response).map(PedidoHistorialModel.fromJson).toList();
  }

  Future<PedidoModel> corregirReferenciaTransferencia({
    required int pedidoId,
    required String referenciaTransferencia,
    String observacion = '',
  }) async {
    final response = await _api.put(
      '/api/pedidos/$pedidoId/corregir-referencia',
      body: {
        'referencia_transferencia': referenciaTransferencia.trim(),
        'observacion': observacion.trim(),
      },
    );
    return PedidoModel.fromJson(_parseData(response));
  }

  /* --------------------------------------------------------------------------
   * HELPERS
   * -------------------------------------------------------------------------- */

  String _withQuery(String path, Map<String, dynamic> query) {
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        filtered[key] = value.toString();
      }
    });
    if (filtered.isEmpty) return path;
    return Uri(path: path, queryParameters: filtered).toString();
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _parseData(dynamic response) {
    final map = _asMap(response);
    if (map['data'] is Map) return Map<String, dynamic>.from(map['data']);
    return map;
  }

  Map<String, dynamic>? _parseNullableData(dynamic response) {
    if (response is! Map) return null;
    final map = Map<String, dynamic>.from(response);
    final data = map['data'];
    if (data == null) return null;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  List<Map<String, dynamic>> _parseList(dynamic response) {
    dynamic data = response;
    if (response is Map && response['data'] != null) data = response['data'];
    if (response is Map && response['items'] != null) data = response['items'];
    if (data is! List) return <Map<String, dynamic>>[];
    return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
