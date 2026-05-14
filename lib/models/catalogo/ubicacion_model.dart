class ZonaModel {
  final int id;
  final String nombreZona;
  final String descripcion;
  final bool activo;

  const ZonaModel({
    required this.id,
    required this.nombreZona,
    this.descripcion = '',
    this.activo = true,
  });

  factory ZonaModel.fromJson(Map<String, dynamic> json) => ZonaModel(
        id: _toInt(json['id'] ?? json['zona_id']),
        nombreZona: (json['nombre_zona'] ?? json['zona_nombre'] ?? json['nombre'] ?? 'Zona').toString(),
        descripcion: (json['descripcion'] ?? '').toString(),
        activo: _toBool(json['activo'] ?? true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre_zona': nombreZona,
        'descripcion': descripcion,
        'activo': activo ? 1 : 0,
      };
}

class DepartamentoModel {
  final int id;
  final String nombre;
  final int? zonaId;
  final String zonaNombre;

  const DepartamentoModel({
    required this.id,
    required this.nombre,
    this.zonaId,
    this.zonaNombre = '',
  });

  factory DepartamentoModel.fromJson(Map<String, dynamic> json) => DepartamentoModel(
        id: _toInt(json['id'] ?? json['id_departamento'] ?? json['departamento_id']),
        nombre: (json['nombre'] ?? json['departamento'] ?? json['nombre_departamento'] ?? '').toString(),
        zonaId: _toNullableInt(json['zona_id']),
        zonaNombre: (json['zona_nombre'] ?? json['nombre_zona'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'zona_id': zonaId,
        'zona_nombre': zonaNombre,
      };
}

class MunicipioModel {
  final int id;
  final String nombre;
  final int? departamentoId;

  const MunicipioModel({
    required this.id,
    required this.nombre,
    this.departamentoId,
  });

  factory MunicipioModel.fromJson(Map<String, dynamic> json) => MunicipioModel(
        id: _toInt(json['id'] ?? json['id_municipio'] ?? json['municipio_id']),
        nombre: (json['nombre'] ?? json['municipio'] ?? json['nombre_municipio'] ?? '').toString(),
        departamentoId: _toNullableInt(json['departamento_id']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'departamento_id': departamentoId,
      };
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value.toString());
  return parsed == 0 ? null : parsed;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  final text = value?.toString().toLowerCase().trim() ?? '';
  return text == '1' || text == 'true' || text == 'si' || text == 'sí';
}
