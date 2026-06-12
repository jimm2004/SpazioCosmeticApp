class ProductoCatalogo {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double precioFinal;
  final Map<String, dynamic>? categoria;
  final List<Map<String, dynamic>> imagenes;
  final bool tieneStock;
  final int stock;
  final int totalImagenes;
  final bool activo;

  const ProductoCatalogo({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.precioFinal,
    this.categoria,
    required this.imagenes,
    required this.tieneStock,
    this.stock = 0,
    this.totalImagenes = 0,
    this.activo = true,
  });

  factory ProductoCatalogo.fromJson(Map<String, dynamic> json) {
    final inventario = json['inventario'] is Map
        ? Map<String, dynamic>.from(json['inventario'] as Map)
        : const <String, dynamic>{};

    final stock = _toInt(
      json['cantidad_stock'] ??
          json['stock'] ??
          json['existencia'] ??
          inventario['cantidad_stock'] ??
          0,
    );

    final precioVenta = _toDouble(json['precio_venta'] ?? json['precio'] ?? 0);
    final precioFinal = _toDouble(
      json['precio_final'] ??
          json['precio_oferta'] ??
          json['precio_venta'] ??
          json['precio'] ??
          0,
    );

    final categoriaMap = _parseCategoria(json);
    final imgs = _parseImagenes(json, precioFinal: precioFinal, precioVenta: precioVenta);

    return ProductoCatalogo(
      idProducto: _toInt(json['id_producto'] ?? json['producto_master_id'] ?? json['id']),
      nombre: _cleanText(json['nombre'] ?? json['name'], fallback: 'Producto'),
      descripcion: _cleanText(json['descripcion'] ?? json['description']),
      precioVenta: precioVenta,
      precioFinal: precioFinal,
      categoria: categoriaMap.isEmpty ? null : categoriaMap,
      imagenes: imgs,
      tieneStock: _toBool(json['tiene_stock'] ?? json['disponible'] ?? (stock > 0)),
      stock: stock,
      totalImagenes: _toInt(json['total_imagenes'] ?? imgs.length),
      activo: _toBool(json['activo'] ?? true),
    );
  }

  int? get categoriaId {
    final value = categoria?['id_categoria'] ?? categoria?['id'] ?? categoria?['categoria_id'];
    return _toNullableInt(value);
  }

  String get categoriaNombre {
    final value = categoria?['nombre_categoria'] ?? categoria?['nombre'] ?? categoria?['linea'] ?? 'Sin línea';
    final text = value.toString().trim();
    return text.isEmpty || text.toLowerCase() == 'null' ? 'Sin línea' : text;
  }

  String get lineaNombre => categoriaNombre;

  int? get imagenPrincipalId {
    final principal = _imagenPrincipalMap;
    return principal == null ? null : _toNullableInt(principal['id'] ?? principal['producto_imagen_id'] ?? principal['imagen_id']);
  }

  String get imagenPrincipal {
    final principal = _imagenPrincipalMap;
    if (principal == null) return '';

    final url = _firstValidString([
      principal['imagen_url'],
      principal['url'],
      principal['img'],
      principal['imagen'],
    ]);

    return url;
  }

  Map<String, dynamic>? get _imagenPrincipalMap {
    if (imagenes.isEmpty) return null;

    for (final img in imagenes) {
      if (_toBool(img['es_principal'])) return img;
    }

    return imagenes.first;
  }

  Map<String, dynamic> toGridMap() {
    final imagenId = imagenPrincipalId;
    final url = imagenPrincipal;

    return {
      'id_producto': idProducto,
      'producto_master_id': idProducto,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_venta': precioVenta,
      'precio_final': precioFinal,
      'categoria': categoria,
      'categoria_nombre': categoriaNombre,
      'id_categoria': categoriaId,
      'imagenes': imagenes,
      'producto_imagen_id': imagenId,
      'imagen_id': imagenId,
      'imagen_url': url,
      'img': url,
      'stock': stock,
      'cantidad_stock': stock,
      'tiene_stock': tieneStock,
      'total_imagenes': totalImagenes,
      'activo': activo,
    };
  }

  ProductoCatalogo copyWith({
    int? idProducto,
    String? nombre,
    String? descripcion,
    double? precioVenta,
    double? precioFinal,
    Map<String, dynamic>? categoria,
    List<Map<String, dynamic>>? imagenes,
    bool? tieneStock,
    int? stock,
    int? totalImagenes,
    bool? activo,
  }) {
    return ProductoCatalogo(
      idProducto: idProducto ?? this.idProducto,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioVenta: precioVenta ?? this.precioVenta,
      precioFinal: precioFinal ?? this.precioFinal,
      categoria: categoria ?? this.categoria,
      imagenes: imagenes ?? this.imagenes,
      tieneStock: tieneStock ?? this.tieneStock,
      stock: stock ?? this.stock,
      totalImagenes: totalImagenes ?? this.totalImagenes,
      activo: activo ?? this.activo,
    );
  }

  static Map<String, dynamic> _parseCategoria(Map<String, dynamic> json) {
    if (json['categoria'] is Map) {
      return Map<String, dynamic>.from(json['categoria'] as Map);
    }

    final map = <String, dynamic>{};

    final id = json['id_categoria'] ?? json['categoria_id'];
    final nombre = json['nombre_categoria'] ?? json['categoria_nombre'] ?? json['linea'];
    final descripcion = json['categoria_descripcion'];

    if (id != null) map['id_categoria'] = id;
    if (nombre != null) map['nombre_categoria'] = nombre;
    if (descripcion != null) map['descripcion'] = descripcion;

    return map;
  }

  static List<Map<String, dynamic>> _parseImagenes(
    Map<String, dynamic> json, {
    required double precioFinal,
    required double precioVenta,
  }) {
    final result = <Map<String, dynamic>>[];
    final seenUrls = <String>{};
    final seenIds = <int>{};

    void addImage(Map<String, dynamic> raw) {
      final url = _firstValidString([
        raw['imagen_url'],
        raw['url'],
        raw['img'],
        raw['imagen'],
      ]);

      if (url.isEmpty) return;

      final id = _toNullableInt(raw['id'] ?? raw['producto_imagen_id'] ?? raw['imagen_id']);
      if (id != null && seenIds.contains(id)) return;
      if (seenUrls.contains(url)) return;

      if (id != null) seenIds.add(id);
      seenUrls.add(url);

      result.add({
        ...raw,
        if (id != null) 'id': id,
        'imagen_url': url,
        'url': url,
        'precio_venta': _toDouble(raw['precio_venta'] ?? precioVenta),
        'precio_final': _toDouble(raw['precio_final'] ?? raw['precio_venta'] ?? precioFinal),
        'es_principal': _toBool(raw['es_principal'] ?? result.isEmpty),
        'activo': _toBool(raw['activo'] ?? true),
      });
    }

    final principal = json['imagen_principal'];
    if (principal is Map) {
      addImage(Map<String, dynamic>.from(principal));
    }

    addImage({
      'id': json['producto_imagen_id'] ?? json['imagen_id'],
      'imagen_url': json['imagen_url'] ?? json['img'] ?? json['imagen'],
      'precio_venta': json['precio_venta'],
      'precio_final': json['precio_final'],
      'es_principal': true,
      'activo': true,
    });

    final rawImgs = json['imagenes'];
    if (rawImgs is List) {
      for (final item in rawImgs) {
        if (item is Map) {
          addImage(Map<String, dynamic>.from(item));
        } else {
          addImage({'imagen_url': item});
        }
      }
    }

    return result;
  }

  static String _firstValidString(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static String _cleanText(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value <= 0 ? null : value;
    if (value is num) return value <= 0 ? null : value.toInt();
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();

    final raw = value
            ?.toString()
            .replaceAll('C\$', '')
            .replaceAll('\$', '')
            .replaceAll(',', '.')
            .trim() ??
        '';

    return double.tryParse(raw) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;

    final text = value?.toString().toLowerCase().trim() ?? '';

    if (text.isEmpty || text == 'null') return false;

    return text == '1' ||
        text == 'true' ||
        text == 'si' ||
        text == 'sí' ||
        text == 'activo' ||
        text == 'available' ||
        text == 'disponible';
  }
}
