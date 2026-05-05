class DatosClienteModel {
  final int? id;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String direccion;
  final int? departamentoId;
  final int? municipioId;
  final String referencia;

  const DatosClienteModel({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.direccion,
    this.departamentoId,
    this.municipioId,
    required this.referencia,
  });

  factory DatosClienteModel.fromJson(Map<String, dynamic> json) {
    return DatosClienteModel(
      id: _toNullableInt(json['id']),
      nombres: (json['nombres'] ?? json['nombre'] ?? '').toString(),
      apellidos: (json['apellidos'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      departamentoId: _toNullableInt(json['departamento_id']),
      municipioId: _toNullableInt(json['municipio_id']),
      referencia: (json['referencia'] ?? json['referencia_direccion'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
        'direccion': direccion,
        'departamento_id': departamentoId,
        'municipio_id': municipioId,
        'referencia': referencia,
      };

  bool get completo => nombres.trim().isNotEmpty && telefono.trim().isNotEmpty && direccion.trim().isNotEmpty;

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
