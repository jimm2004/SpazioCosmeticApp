class DepartamentoModel {
  final int id;
  final String nombre;
  final int? zonaId;

  const DepartamentoModel({required this.id, required this.nombre, this.zonaId});

  factory DepartamentoModel.fromJson(Map<String, dynamic> json) => DepartamentoModel(
        id: _toInt(json['id'] ?? json['id_departamento'] ?? json['departamento_id']),
        nombre: (json['nombre'] ?? json['departamento'] ?? json['nombre_departamento'] ?? '').toString(),
        zonaId: _toNullableInt(json['zona_id']),
      );

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
}

class MunicipioModel {
  final int id;
  final String nombre;
  final int? departamentoId;

  const MunicipioModel({required this.id, required this.nombre, this.departamentoId});

  factory MunicipioModel.fromJson(Map<String, dynamic> json) => MunicipioModel(
        id: _toInt(json['id'] ?? json['id_municipio'] ?? json['municipio_id']),
        nombre: (json['nombre'] ?? json['municipio'] ?? json['nombre_municipio'] ?? '').toString(),
        departamentoId: _toNullableInt(json['departamento_id']),
      );

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
}
