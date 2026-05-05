class TarifaEnvioModel {
  final int id;
  final int? zonaId;
  final String nombreZona;
  final double porcentajeEnvio;
  final bool esDefault;
  final String descripcion;
  final bool activo;

  const TarifaEnvioModel({
    required this.id,
    this.zonaId,
    required this.nombreZona,
    required this.porcentajeEnvio,
    required this.esDefault,
    required this.descripcion,
    required this.activo,
  });

  factory TarifaEnvioModel.fromJson(Map<String, dynamic> json) {
    return TarifaEnvioModel(
      id: _toInt(json['id']),
      zonaId: _toNullableInt(json['zona_id']),
      nombreZona: (json['nombre_zona'] ?? json['zona'] ?? 'Zona').toString(),
      porcentajeEnvio: _toDouble(json['porcentaje_envio']),
      esDefault: _toBool(json['es_default'] ?? false),
      descripcion: (json['descripcion'] ?? '').toString(),
      activo: _toBool(json['activo'] ?? true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'zona_id': zonaId,
        'nombre_zona': nombreZona,
        'porcentaje_envio': porcentajeEnvio,
        'es_default': esDefault ? 1 : 0,
        'descripcion': descripcion,
        'activo': activo ? 1 : 0,
      };

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == '1' || text == 'true' || text == 'si' || text == 'sí';
  }
}
