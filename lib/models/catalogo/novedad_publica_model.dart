class NovedadPublicaModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagenUrl;
  final String? enlaceUrl;
  final int orden;
  final int? productoImagenId;
  final int? productoMasterId;
  final String productoNombre;

  const NovedadPublicaModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagenUrl,
    this.enlaceUrl,
    required this.orden,
    this.productoImagenId,
    this.productoMasterId,
    this.productoNombre = '',
  });

  factory NovedadPublicaModel.fromJson(Map<String, dynamic> json) {
    final imagen = json['imagen_url'] ??
        json['foto_url'] ??
        json['foto'] ??
        json['producto_imagen_url'] ??
        json['imagen_producto_url'];

    return NovedadPublicaModel(
      id: _toInt(json['id_novedad'] ?? json['id']),
      titulo: (json['titulo'] ?? json['nombre'] ?? 'Novedad').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      imagenUrl: _clean(imagen),
      enlaceUrl: _nullable(json['enlace_url']),
      orden: _toInt(json['orden'] ?? 0),
      productoImagenId: _toNullableInt(json['producto_imagen_id']),
      productoMasterId: _toNullableInt(json['producto_master_id']),
      productoNombre: _clean(json['producto_nombre']),
    );
  }

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

  static String _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  static String? _nullable(dynamic value) {
    final text = _clean(value);
    if (text.isEmpty) return null;
    return text;
  }
}
