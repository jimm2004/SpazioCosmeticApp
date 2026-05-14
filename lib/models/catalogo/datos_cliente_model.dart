class DatosClienteModel {
  final int? id;
  final int? userId;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String direccion;
  final int? zonaId;
  final String zonaNombre;
  final int? departamentoId;
  final String departamentoNombre;
  final int? municipioId;
  final String municipioNombre;
  final String referencia;

  const DatosClienteModel({
    this.id,
    this.userId,
    required this.nombres,
    this.apellidos = '',
    required this.telefono,
    required this.direccion,
    this.zonaId,
    this.zonaNombre = '',
    this.departamentoId,
    this.departamentoNombre = '',
    this.municipioId,
    this.municipioNombre = '',
    required this.referencia,
  });

  factory DatosClienteModel.empty({String nombres = ''}) => DatosClienteModel(
        nombres: nombres,
        telefono: '',
        direccion: '',
        referencia: '',
      );

  factory DatosClienteModel.fromJson(Map<String, dynamic> json) {
    return DatosClienteModel(
      id: _toNullableInt(json['id']),
      userId: _toNullableInt(json['user_id']),
      nombres: (json['nombres'] ?? json['nombre'] ?? json['name'] ?? '').toString(),
      apellidos: (json['apellidos'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      direccion: (json['direccion'] ?? json['direccion_cliente'] ?? '').toString(),
      zonaId: _toNullableInt(json['zona_id'] ?? json['envio_zona_id']),
      zonaNombre: (json['zona_nombre'] ?? json['envio_zona_nombre'] ?? '').toString(),
      departamentoId: _toNullableInt(json['departamento_id']),
      departamentoNombre: (json['departamento_nombre'] ?? '').toString(),
      municipioId: _toNullableInt(json['municipio_id']),
      municipioNombre: (json['municipio_nombre'] ?? '').toString(),
      referencia: (json['referencia'] ?? json['referencia_direccion'] ?? '').toString(),
    );
  }

  DatosClienteModel copyWith({
    int? id,
    int? userId,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? direccion,
    int? zonaId,
    String? zonaNombre,
    int? departamentoId,
    String? departamentoNombre,
    int? municipioId,
    String? municipioNombre,
    String? referencia,
    bool limpiarZona = false,
    bool limpiarDepartamento = false,
    bool limpiarMunicipio = false,
  }) {
    return DatosClienteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      zonaId: limpiarZona ? null : zonaId ?? this.zonaId,
      zonaNombre: zonaNombre ?? this.zonaNombre,
      departamentoId: limpiarDepartamento ? null : departamentoId ?? this.departamentoId,
      departamentoNombre: departamentoNombre ?? this.departamentoNombre,
      municipioId: limpiarMunicipio ? null : municipioId ?? this.municipioId,
      municipioNombre: municipioNombre ?? this.municipioNombre,
      referencia: referencia ?? this.referencia,
    );
  }

  Map<String, dynamic> toJson() => {
        'nombres': nombres.trim(),
        'apellidos': apellidos.trim().isEmpty ? null : apellidos.trim(),
        'telefono': telefono.trim(),
        'direccion': direccion.trim(),
        'zona_id': zonaId,
        'departamento_id': departamentoId,
        'municipio_id': municipioId,
        'referencia': referencia.trim(),
      };

  bool get completo {
    return nombres.trim().isNotEmpty &&
        telefono.trim().isNotEmpty &&
        direccion.trim().isNotEmpty &&
        referencia.trim().isNotEmpty &&
        departamentoId != null &&
        municipioId != null;
  }

  String get nombreCompleto => [nombres, apellidos].where((v) => v.trim().isNotEmpty).join(' ').trim();

  String get ubicacionResumen {
    final partes = <String>[];
    if (zonaNombre.trim().isNotEmpty) partes.add(zonaNombre.trim());
    if (departamentoNombre.trim().isNotEmpty) partes.add(departamentoNombre.trim());
    if (municipioNombre.trim().isNotEmpty) partes.add(municipioNombre.trim());
    return partes.join(' · ');
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value == 0 ? null : value;
    if (value is num) return value.toInt() == 0 ? null : value.toInt();
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed == 0) return null;
    return parsed;
  }
}
