class NovedadPublicaModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagenUrl;
  final String? enlaceUrl;
  final int orden;

  const NovedadPublicaModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagenUrl,
    this.enlaceUrl,
    required this.orden,
  });

  factory NovedadPublicaModel.fromJson(Map<String, dynamic> json) {
    return NovedadPublicaModel(
      id: _toInt(json['id_novedad'] ?? json['id']),
      titulo: (json['titulo'] ?? 'Novedad').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      imagenUrl: (json['imagen_url'] ?? json['foto_url'] ?? json['foto'] ?? '').toString(),
      enlaceUrl: _nullable(json['enlace_url']),
      orden: _toInt(json['orden'] ?? 0),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}
