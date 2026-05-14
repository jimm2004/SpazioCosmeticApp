class ProductoCatalogo {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double precioFinal;
  final Map<String, dynamic>? categoria;
  final List<Map<String, dynamic>> imagenes;
  final bool tieneStock;

  const ProductoCatalogo({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.precioFinal,
    this.categoria,
    required this.imagenes,
    required this.tieneStock,
  });

  factory ProductoCatalogo.fromJson(Map<String, dynamic> json) {
    final imgs = <Map<String, dynamic>>[];
    final rawImgs = json['imagenes'];
    if (rawImgs is List) {
      for (final item in rawImgs) {
        if (item is Map) imgs.add(Map<String, dynamic>.from(item));
      }
    }
    if (imgs.isEmpty && json['imagen_url'] != null) {
      imgs.add({
        'id': json['producto_imagen_id'] ?? json['imagen_id'],
        'imagen_url': json['imagen_url'],
        'precio_final': json['precio_final'],
      });
    }
    return ProductoCatalogo(
      idProducto: _toInt(json['id_producto'] ?? json['producto_master_id'] ?? json['id']),
      nombre: (json['nombre'] ?? 'Producto').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precioVenta: _toDouble(json['precio_venta']),
      precioFinal: _toDouble(json['precio_final'] ?? json['precio_venta']),
      categoria: json['categoria'] is Map ? Map<String, dynamic>.from(json['categoria']) : null,
      imagenes: imgs,
      tieneStock: _toBool(json['tiene_stock'] ?? true),
    );
  }

  String get categoriaNombre {
    final value = categoria?['nombre_categoria'] ?? categoria?['nombre'] ?? 'General';
    return value.toString();
  }

  String get imagenPrincipal {
    for (final img in imagenes) {
      final url = (img['imagen_url'] ?? img['url'] ?? '').toString();
      if (url.trim().isNotEmpty && url.toLowerCase() != 'null') return url;
    }
    return '';
  }

  int? get imagenPrincipalId {
    if (imagenes.isEmpty) return null;
    return _toNullableInt(imagenes.first['id']);
  }

  Map<String, dynamic> toGridMap() => {
        'id_producto': idProducto,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio_venta': precioVenta,
        'precio_final': precioFinal,
        'categoria': categoria,
        'imagenes': imagenes,
        'imagen_url': imagenPrincipal,
        'tiene_stock': tieneStock,
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
