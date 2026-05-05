import '../models/catalogo/carrito_model.dart';
import '../models/catalogo/datos_cliente_model.dart';
import '../models/catalogo/metodo_pago_model.dart';
import '../models/catalogo/novedad_publica_model.dart';
import '../models/catalogo/producto_catalogo_model.dart';
import '../models/catalogo/tarifa_envio_model.dart';
import '../models/catalogo/ubicacion_model.dart';
import 'api_service.dart';

class CatalogoService {
  final ApiService _api = ApiService();

  Future<List<ProductoCatalogo>> obtenerProductos() async {
    final response = await _api.get('/api/catalogo/productos');
    return _parseList(response).map((item) => ProductoCatalogo.fromJson(item)).toList();
  }

  Future<List<ProductoCatalogo>> buscarProductos(String nombre) async {
    final response = await _api.get('/api/catalogo/buscar/${Uri.encodeComponent(nombre)}');
    return _parseList(response).map((item) => ProductoCatalogo.fromJson(item)).toList();
  }

  Future<List<NovedadPublicaModel>> obtenerNovedades() async {
    final response = await _api.get('/api/catalogo/novedades');
    return _parseList(response).map((item) => NovedadPublicaModel.fromJson(item)).toList();
  }

  Future<List<MetodoPagoModel>> obtenerMetodosPago() async {
    final response = await _api.get('/api/catalogo/metodos-pago');
    return _parseList(response).map((item) => MetodoPagoModel.fromJson(item)).toList();
  }

  Future<List<TarifaEnvioModel>> obtenerTarifasEnvio() async {
    final response = await _api.get('/api/catalogo/tarifas-envio');
    return _parseList(response).map((item) => TarifaEnvioModel.fromJson(item)).toList();
  }

  Future<List<TarifaEnvioModel>> obtenerEnvios() async {
    return obtenerTarifasEnvio();
  }

  Future<List<DepartamentoModel>> obtenerDepartamentos() async {
    final response = await _api.get('/api/catalogo/departamentos');
    return _parseList(response).map((item) => DepartamentoModel.fromJson(item)).toList();
  }

  Future<List<MunicipioModel>> obtenerMunicipios(int departamentoId) async {
    final response = await _api.get('/api/catalogo/municipios/$departamentoId');
    return _parseList(response).map((item) => MunicipioModel.fromJson(item)).toList();
  }

  Future<Map<String, dynamic>> previewCostoEnvio({
    required double subtotal,
    int? departamentoId,
    int? municipioId,
  }) async {
    final response = await _api.post(
      '/api/catalogo/preview-envio',
      body: {
        'subtotal': subtotal,
        'departamento_id': departamentoId,
        'municipio_id': municipioId,
      },
    );
    return _parseData(response);
  }

  Future<CarritoModel> verCarrito() async {
    final response = await _api.get('/api/carrito');
    return CarritoModel.fromJson(Map<String, dynamic>.from(response));
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
    return CarritoModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CarritoModel> editarItemCarrito({required int detalleId, required int cantidad}) async {
    final response = await _api.put('/api/carrito/items/$detalleId', body: {'cantidad': cantidad});
    return CarritoModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CarritoModel> quitarItemCarrito(int detalleId) async {
    final response = await _api.delete('/api/carrito/items/$detalleId');
    return CarritoModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<CarritoModel> vaciarCarrito() async {
    final response = await _api.delete('/api/carrito/vaciar');
    return CarritoModel.fromJson(Map<String, dynamic>.from(response));
  }

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

  Future<Map<String, dynamic>> realizarPedido({
    required int metodoPagoId,
    required String referenciaTransferencia,
    String observacion = '',
    int? envioId,
  }) async {
    final response = await _api.post(
      '/api/pedidos/realizar',
      body: {
        'envio_id': envioId,
        'metodo_pago_id': metodoPagoId,
        'referencia_transferencia': referenciaTransferencia,
        'observacion': observacion,
        'tipo_pago': 'transferencia',
      },
    );
    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> listarPedidos() async {
    final response = await _api.get('/api/pedidos');
    return _parseList(response);
  }

  Map<String, dynamic> _parseData(dynamic response) {
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map['data'] is Map) return Map<String, dynamic>.from(map['data']);
      return map;
    }
    return <String, dynamic>{};
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
