class CarritoModel {
  final int? id;
  final List<CarritoItemModel> items;
  final double subtotal;
  final int totalItems;

  const CarritoModel({this.id, required this.items, required this.subtotal, required this.totalItems});

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final rawItems = root['items'] ?? root['detalles'] ?? root['productos'] ?? [];
    final items = <CarritoItemModel>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) items.add(CarritoItemModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    final subtotal = _toDouble(root['subtotal'] ?? root['total'] ?? items.fold<double>(0, (s, i) => s + i.subtotal));
    return CarritoModel(
      id: _toNullableInt(root['id'] ?? root['carrito_id']),
      items: items,
      subtotal: subtotal,
      totalItems: _toInt(root['total_items'] ?? root['cantidad_items'] ?? items.fold<int>(0, (s, i) => s + i.cantidad)),
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}

class CarritoItemModel {
  final int detalleId;
  final int productoMasterId;
  final int? productoImagenId;
  final String nombre;
  final String imagenUrl;
  final double precioUnitario;
  final int cantidad;
  final double subtotal;

  String get imagen => imagenUrl;
  double get total => subtotal;
  double get precio => precioUnitario;
  int get id => detalleId;

  const CarritoItemModel({
    required this.detalleId,
    required this.productoMasterId,
    this.productoImagenId,
    required this.nombre,
    required this.imagenUrl,
    required this.precioUnitario,
    required this.cantidad,
    required this.subtotal,
  });

  factory CarritoItemModel.fromJson(Map<String, dynamic> json) {
    final producto = json['producto'] is Map ? Map<String, dynamic>.from(json['producto']) : <String, dynamic>{};
    return CarritoItemModel(
      detalleId: _toInt(json['detalle_id'] ?? json['id'] ?? json['id_detalle']),
      productoMasterId: _toInt(json['producto_master_id'] ?? json['id_producto'] ?? producto['id_producto']),
      productoImagenId: _toNullableInt(json['producto_imagen_id'] ?? json['imagen_id']),
      nombre: (json['nombre'] ?? producto['nombre'] ?? 'Producto').toString(),
      imagenUrl: (json['imagen_url'] ?? producto['imagen_url'] ?? '').toString(),
      precioUnitario: _toDouble(json['precio_unitario'] ?? json['precio_final'] ?? json['precio']),
      cantidad: _toInt(json['cantidad'] ?? 1),
      subtotal: _toDouble(json['subtotal'] ?? 0),
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

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}
