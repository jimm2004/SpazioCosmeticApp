class ProductoAdminModel {
  final int idProducto;
  final String nombre;
  final String descripcion;
  final double precioVenta;
  final int cantidadStock;
  final String? imagenUrl;
  final bool? activo; // <-- 1. Nuevo campo para la visibilidad

  ProductoAdminModel({
    required this.idProducto,
    required this.nombre,
    required this.descripcion,
    required this.precioVenta,
    required this.cantidadStock,
    this.imagenUrl,
    this.activo, // <-- 2. Lo agregamos al constructor
  });

  factory ProductoAdminModel.fromJson(Map<String, dynamic> json) {
    // Validación segura para el booleano (soporta 1, 0, true, false o null)
    bool isActivo = true; // Por defecto asumimos que es visible
    if (json['activo'] != null) {
      isActivo = json['activo'] == 1 || json['activo'] == true || json['activo'] == '1';
    }

    return ProductoAdminModel(
      idProducto: int.tryParse(json['id_producto']?.toString() ?? '0') ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      precioVenta: double.tryParse(json['precio_venta']?.toString() ?? '0') ?? 0,
      cantidadStock: int.tryParse(
            json['inventario']?['cantidad_stock']?.toString() ?? '0',
          ) ??
          0,
      imagenUrl: json['imagen_url']?.toString(),
      activo: isActivo, // <-- 3. Lo mapeamos desde el JSON
    );
  }
}