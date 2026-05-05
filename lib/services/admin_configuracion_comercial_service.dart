import '../models/catalogo/metodo_pago_model.dart';
import '../models/catalogo/tarifa_envio_model.dart';
import 'api_service.dart';

class AdminConfiguracionComercialService {
  final ApiService _api = ApiService();

  Future<List<MetodoPagoModel>> listarMetodosPago() async {
    final response = await _api.get('/api/admin/metodos-pago');
    return _parseList(response).map((item) => MetodoPagoModel.fromJson(item)).toList();
  }

  Future<MetodoPagoModel> guardarMetodoPago({
    int? id,
    required String banco,
    required String moneda,
    required String titular,
    required String numeroCuenta,
    String descripcion = '',
    int orden = 1,
    bool activo = true,
  }) async {
    final body = {
      'banco': banco,
      'moneda': moneda,
      'tipo_pago': 'transferencia',
      'titular': titular,
      'numero_cuenta': numeroCuenta,
      'descripcion': descripcion,
      'orden': orden,
      'activo': activo ? 1 : 0,
    };
    final response = id == null
        ? await _api.post('/api/admin/metodos-pago', body: body)
        : await _api.put('/api/admin/metodos-pago/$id', body: body);
    return MetodoPagoModel.fromJson(_parseData(response));
  }

  Future<MetodoPagoModel> cambiarEstadoMetodoPago(int id, bool activo) async {
    final response = await _api.post('/api/admin/metodos-pago/$id/estado', body: {'activo': activo ? 1 : 0});
    return MetodoPagoModel.fromJson(_parseData(response));
  }

  Future<List<TarifaEnvioModel>> listarTarifasEnvio() async {
    final response = await _api.get('/api/admin/tarifas-envio');
    return _parseList(response).map((item) => TarifaEnvioModel.fromJson(item)).toList();
  }

  Future<TarifaEnvioModel> actualizarTarifaEnvio({
    required int id,
    required double porcentajeEnvio,
    required bool activo,
    String descripcion = '',
  }) async {
    final response = await _api.put(
      '/api/admin/tarifas-envio/$id',
      body: {
        'porcentaje_envio': porcentajeEnvio,
        'activo': activo ? 1 : 0,
        'descripcion': descripcion,
      },
    );
    return TarifaEnvioModel.fromJson(_parseData(response));
  }

  Map<String, dynamic> _parseData(dynamic response) {
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      if (map['data'] is Map) return Map<String, dynamic>.from(map['data']);
      return map;
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _parseList(dynamic response) {
    dynamic data = response;
    if (response is Map && response['data'] != null) data = response['data'];
    if (data is! List) return <Map<String, dynamic>>[];
    return data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
