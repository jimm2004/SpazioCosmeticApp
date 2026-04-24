class ProductoCatalogoModel {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double precioFinal;
  final String? imagenUrl;
  final int cantidadStock;
  final bool activo;
  final bool tieneStock;
  final List<Map<String, dynamic>> imagenes;

  ProductoCatalogoModel({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.precioFinal,
    required this.imagenUrl,
    required this.cantidadStock,
    required this.activo,
    required this.tieneStock,
    required this.imagenes,
  });

  factory ProductoCatalogoModel.fromJson(Map<String, dynamic> json) {
    final inventario = json['inventario'] is Map
        ? Map<String, dynamic>.from(json['inventario'])
        : <String, dynamic>{};

    final imagenesRaw = json['imagenes'];

    return ProductoCatalogoModel(
      idProducto: _toInt(json['id_producto']),
      nombre: (json['nombre'] ?? 'Producto sin nombre').toString(),
      descripcion: (json['descripcion'] ?? 'Sin descripción disponible').toString(),
      precioVenta: _toDouble(json['precio_venta']),
      precioFinal: _toDouble(json['precio_final'] ?? json['precio_venta']),
      imagenUrl: _cleanString(json['imagen_url']),
      cantidadStock: _toInt(inventario['cantidad_stock']),
      activo: _toBool(json['activo']),
      tieneStock: _toBool(json['tiene_stock']) || _toInt(inventario['cantidad_stock']) > 0,
      imagenes: imagenesRaw is List
          ? imagenesRaw
              .where((e) => e is Map)
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toProductCardMap() {
    return {
      'id': idProducto.toString(),
      'id_producto': idProducto,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': '\$${precioFinal.toStringAsFixed(2)}',
      'precio_num': precioFinal,
      'precio_venta': precioVenta,
      'precio_final': precioFinal,
      'rating': 5,
      'descuento': null,
      'img': imagenUrl ?? '',
      'imagen_url': imagenUrl ?? '',
      'cantidad_stock': cantidadStock,
      'activo': activo,
      'imagenes': imagenes,
      'tiene_stock': tieneStock,
    };
  }

  bool get tieneImagen {
    final foto = (imagenUrl ?? '').trim();
    return foto.isNotEmpty && foto.toLowerCase() != 'null';
  }

  static String? _cleanString(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value == true || value == 1) return true;

    final text = value.toString().toLowerCase().trim();

    return text == '1' || text == 'true' || text == 'activo';
  }
}