class ProductoAdminModel {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double precioFinal;
  final int cantidadStock;
  final String? imagen;
  final String? imagenUrl;
  final bool? activo;
  final int totalImagenes;
  final List<ProductoImagenAdminModel> imagenes;
  final ProductoImagenAdminModel? imagenPrincipal;

  ProductoAdminModel({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.precioFinal,
    required this.cantidadStock,
    this.imagen,
    this.imagenUrl,
    this.activo,
    required this.totalImagenes,
    required this.imagenes,
    this.imagenPrincipal,
  });

  factory ProductoAdminModel.fromJson(Map<String, dynamic> json) {
    final inventario = json['inventario'] is Map
        ? Map<String, dynamic>.from(json['inventario'])
        : <String, dynamic>{};

    final imagenesRaw = json['imagenes'];

    final List<ProductoImagenAdminModel> listaImagenes = imagenesRaw is List
        ? imagenesRaw
            .where((e) => e is Map)
            .map(
              (e) => ProductoImagenAdminModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList()
        : [];

    ProductoImagenAdminModel? principal;

    if (json['imagen_principal'] is Map) {
      principal = ProductoImagenAdminModel.fromJson(
        Map<String, dynamic>.from(json['imagen_principal'] as Map),
      );
    } else if (listaImagenes.isNotEmpty) {
      principal = listaImagenes.firstWhere(
        (img) => img.esPrincipal,
        orElse: () => listaImagenes.first,
      );
    }

    final double precioVenta = _toDouble(json['precio_venta']);

    final double precioFinal = _toDouble(
      json['precio_final'] ??
          principal?.precioFinal ??
          principal?.precioVenta ??
          json['precio_venta'],
    );

    final String? imagenUrl = _cleanString(
      json['imagen_url'] ?? principal?.imagenUrl,
    );

    final String? imagen = _cleanString(
      json['imagen'] ?? principal?.imagen,
    );

    return ProductoAdminModel(
      idProducto: _toInt(json['id_producto']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precioVenta: precioVenta,
      precioFinal: precioFinal,
      cantidadStock: _toInt(inventario['cantidad_stock']),
      imagen: imagen,
      imagenUrl: imagenUrl,
      activo: _toBoolNullable(json['activo']),
      totalImagenes: _toInt(json['total_imagenes'] ?? listaImagenes.length),
      imagenes: listaImagenes,
      imagenPrincipal: principal,
    );
  }

  bool get tieneImagen {
    final url = imagenUrl?.trim() ?? '';
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  bool get esVisible {
    return activo ?? true;
  }

  bool get tieneStock {
    return cantidadStock > 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_venta': precioVenta,
      'precio_final': precioFinal,
      'cantidad_stock': cantidadStock,
      'imagen': imagen,
      'imagen_url': imagenUrl,
      'activo': activo,
      'total_imagenes': totalImagenes,
      'imagenes': imagenes.map((e) => e.toJson()).toList(),
      'imagen_principal': imagenPrincipal?.toJson(),
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static bool? _toBoolNullable(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;

    final text = value.toString().toLowerCase().trim();

    if (text == '1' || text == 'true' || text == 'activo') return true;
    if (text == '0' || text == 'false' || text == 'inactivo') return false;

    return null;
  }

  static String? _cleanString(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }
}

class ProductoImagenAdminModel {
  final int id;
  final int productoMasterId;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final double precioFinal;
  final String? imagen;
  final String? imagenUrl;
  final bool activo;
  final bool esPrincipal;
  final int orden;

  ProductoImagenAdminModel({
    required this.id,
    required this.productoMasterId,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.precioFinal,
    this.imagen,
    this.imagenUrl,
    required this.activo,
    required this.esPrincipal,
    required this.orden,
  });

  factory ProductoImagenAdminModel.fromJson(Map<String, dynamic> json) {
    final double precioVenta = _toDouble(json['precio_venta']);

    return ProductoImagenAdminModel(
      id: _toInt(json['id']),
      productoMasterId: _toInt(json['producto_master_id']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precioVenta: precioVenta,
      precioFinal: _toDouble(json['precio_final'] ?? precioVenta),
      imagen: _cleanString(json['imagen']),
      imagenUrl: _cleanString(json['imagen_url']),
      activo: _toBool(json['activo']),
      esPrincipal: _toBool(json['es_principal']),
      orden: _toInt(json['orden']),
    );
  }

  bool get tieneImagen {
    final url = imagenUrl?.trim() ?? '';
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto_master_id': productoMasterId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_venta': precioVenta,
      'precio_final': precioFinal,
      'imagen': imagen,
      'imagen_url': imagenUrl,
      'activo': activo,
      'es_principal': esPrincipal,
      'orden': orden,
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static bool _toBool(dynamic value) {
    if (value == true || value == 1) return true;

    final text = value.toString().toLowerCase().trim();

    return text == '1' || text == 'true' || text == 'activo';
  }

  static String? _cleanString(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }
}