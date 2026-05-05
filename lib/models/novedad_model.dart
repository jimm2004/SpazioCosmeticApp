class NovedadModel {
  final int idNovedad;
  final String titulo;
  final String descripcion;
  final int? productoImagenId;
  final String? foto;
  final String? fotoUrl;
  final String? enlaceUrl;
  final bool activo;
  final int orden;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? productoImagen;

  const NovedadModel({
    required this.idNovedad,
    required this.titulo,
    required this.descripcion,
    this.productoImagenId,
    this.foto,
    this.fotoUrl,
    this.enlaceUrl,
    required this.activo,
    required this.orden,
    this.createdAt,
    this.updatedAt,
    this.productoImagen,
  });

  factory NovedadModel.fromJson(Map<String, dynamic> json) {
    return NovedadModel(
      idNovedad: _toInt(json['id_novedad'] ?? json['id'] ?? 0),
      titulo: (json['titulo'] ?? json['title'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? json['description'] ?? '').toString(),
      productoImagenId: _toNullableInt(
        json['producto_imagen_id'] ?? json['productoImagenId'],
      ),
      foto: _toNullableString(json['foto']),
      fotoUrl: _toNullableString(
        json['foto_url'] ??
            json['imagen_url'] ??
            json['image_url'] ??
            json['url_foto'],
      ),
      enlaceUrl: _toNullableString(json['enlace_url'] ?? json['link']),
      activo: _toBool(json['activo'] ?? json['active'] ?? true),
      orden: _toInt(json['orden'] ?? json['order'] ?? 0),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
      productoImagen: json['producto_imagen'] is Map
          ? Map<String, dynamic>.from(json['producto_imagen'])
          : json['productoImagen'] is Map
              ? Map<String, dynamic>.from(json['productoImagen'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_novedad': idNovedad,
      'titulo': titulo,
      'descripcion': descripcion,
      'producto_imagen_id': productoImagenId,
      'foto': foto,
      'foto_url': fotoUrl,
      'enlace_url': enlaceUrl,
      'activo': activo ? 1 : 0,
      'orden': orden,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'producto_imagen': productoImagen,
    };
  }

  String get imagenPrincipal {
    final direct = _firstValid([
      fotoUrl,
      foto,
      productoImagen?['imagen_url'],
      productoImagen?['foto_url'],
      productoImagen?['imagen'],
    ]);

    return direct ?? '';
  }

  bool get tieneImagen => imagenPrincipal.trim().isNotEmpty;

  NovedadModel copyWith({
    int? idNovedad,
    String? titulo,
    String? descripcion,
    int? productoImagenId,
    String? foto,
    String? fotoUrl,
    String? enlaceUrl,
    bool? activo,
    int? orden,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? productoImagen,
  }) {
    return NovedadModel(
      idNovedad: idNovedad ?? this.idNovedad,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      productoImagenId: productoImagenId ?? this.productoImagenId,
      foto: foto ?? this.foto,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      enlaceUrl: enlaceUrl ?? this.enlaceUrl,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productoImagen: productoImagen ?? this.productoImagen,
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

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;

    return int.tryParse(text);
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;

    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == '1' || text == 'true' || text == 'si' || text == 'sí';
  }

  static DateTime? _toDate(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return DateTime.tryParse(text);
  }

  static String? _toNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static String? _firstValid(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
  }
}
