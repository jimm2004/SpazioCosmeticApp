class ProductoNovedadBusquedaModel {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final List<ProductoImagenNovedadOption> imagenes;

  const ProductoNovedadBusquedaModel({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.imagenes,
  });

  factory ProductoNovedadBusquedaModel.fromJson(Map<String, dynamic> json) {
    final rawImagenes = json['imagenes'];

    final imagenes = rawImagenes is List
        ? rawImagenes
            .whereType<Map>()
            .map((item) => ProductoImagenNovedadOption.fromJson(
                  Map<String, dynamic>.from(item),
                  productoNombre: (json['nombre'] ?? 'Producto').toString(),
                ))
            .where((item) => item.id > 0)
            .toList()
        : <ProductoImagenNovedadOption>[];

    imagenes.sort((a, b) {
      if (a.esPrincipal && !b.esPrincipal) return -1;
      if (!a.esPrincipal && b.esPrincipal) return 1;
      final orden = a.orden.compareTo(b.orden);
      if (orden != 0) return orden;
      return a.id.compareTo(b.id);
    });

    return ProductoNovedadBusquedaModel(
      idProducto: _toInt(json['id_producto'] ?? json['id'] ?? 0),
      nombre: (json['nombre'] ?? 'Producto sin nombre').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      imagenes: imagenes,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProductoImagenNovedadOption {
  final int id;
  final int? productoMasterId;
  final String productoNombre;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final bool activo;
  final bool esPrincipal;
  final int orden;
  final double precioFinal;

  const ProductoImagenNovedadOption({
    required this.id,
    this.productoMasterId,
    required this.productoNombre,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.activo,
    required this.esPrincipal,
    required this.orden,
    required this.precioFinal,
  });

  factory ProductoImagenNovedadOption.fromJson(
    Map<String, dynamic> json, {
    String productoNombre = 'Producto',
  }) {
    return ProductoImagenNovedadOption(
      id: _toInt(json['id'] ?? json['id_imagen'] ?? 0),
      productoMasterId: _toNullableInt(
        json['producto_master_id'] ?? json['producto_id'],
      ),
      productoNombre: productoNombre,
      nombre: (json['nombre'] ?? productoNombre).toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      imagenUrl: (json['imagen_url'] ?? json['foto_url'] ?? json['imagen'] ?? '')
          .toString(),
      activo: _toBool(json['activo'] ?? true),
      esPrincipal: _toBool(json['es_principal'] ?? false),
      orden: _toInt(json['orden'] ?? 0),
      precioFinal: _toDouble(json['precio_final'] ?? json['precio_venta'] ?? 0),
    );
  }

  factory ProductoImagenNovedadOption.soloId(int id) {
    return ProductoImagenNovedadOption(
      id: id,
      productoMasterId: null,
      productoNombre: 'Imagen vinculada',
      nombre: 'Imagen #$id',
      descripcion: '',
      imagenUrl: '',
      activo: true,
      esPrincipal: false,
      orden: 0,
      precioFinal: 0,
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == '1' || text == 'true' || text == 'si' || text == 'sí';
  }
}
