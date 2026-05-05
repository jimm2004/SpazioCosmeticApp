class EnvioModel {
  final int id;
  final String nombre;
  final String tipoCalculo;
  final double porcentajeEnvio;
  final double montoFijo;
  final double minimoCompra;
  final String descripcion;
  final bool activo;

  const EnvioModel({
    required this.id,
    required this.nombre,
    required this.tipoCalculo,
    required this.porcentajeEnvio,
    required this.montoFijo,
    required this.minimoCompra,
    required this.descripcion,
    required this.activo,
  });

  factory EnvioModel.fromJson(Map<String, dynamic> json) {
    return EnvioModel(
      id: _toInt(json['id']),
      nombre: (json['nombre'] ?? 'Envío').toString(),
      tipoCalculo: (json['tipo_calculo'] ?? 'monto_fijo').toString(),
      porcentajeEnvio: _toDouble(json['porcentaje_envio']),
      montoFijo: _toDouble(json['monto_fijo']),
      minimoCompra: _toDouble(json['minimo_compra']),
      descripcion: (json['descripcion'] ?? '').toString(),
      activo: _toBool(json['activo'], defaultValue: true),
    );
  }

  double costoEstimado(double subtotal) {
    if (!activo) return 0;
    if (subtotal < minimoCompra) return 0;
    if (tipoCalculo == 'porcentaje') {
      return double.parse((subtotal * (porcentajeEnvio / 100)).toStringAsFixed(2));
    }
    return montoFijo;
  }

  String etiqueta(double subtotal) {
    final costo = costoEstimado(subtotal);
    if (costo <= 0) return '$nombre - Gratis';
    return '$nombre - \$${costo.toStringAsFixed(2)}';
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

bool _toBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value == 1;
  return value.toString() == '1' || value.toString().toLowerCase() == 'true';
}
