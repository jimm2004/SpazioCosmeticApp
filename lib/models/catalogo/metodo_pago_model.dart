class MetodoPagoModel {
  final int id;
  final String banco;
  final String moneda;
  final String tipoPago;
  final String titular;
  final String numeroCuenta;
  final String descripcion;
  final int orden;
  final bool activo;

  const MetodoPagoModel({
    required this.id,
    required this.banco,
    required this.moneda,
    required this.tipoPago,
    required this.titular,
    required this.numeroCuenta,
    required this.descripcion,
    required this.orden,
    required this.activo,
  });

  factory MetodoPagoModel.fromJson(Map<String, dynamic> json) {
    return MetodoPagoModel(
      id: _toInt(json['id']),
      banco: (json['banco'] ?? '').toString(),
      moneda: (json['moneda'] ?? r'$').toString(),
      tipoPago: (json['tipo_pago'] ?? 'transferencia').toString(),
      titular: (json['titular'] ?? '').toString(),
      numeroCuenta: (json['numero_cuenta'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      orden: _toInt(json['orden'] ?? 0),
      activo: _toBool(json['activo'] ?? true),
    );
  }

  String get nombreVisible => '$banco $moneda';

  Map<String, dynamic> toJson() => {
        'id': id,
        'banco': banco,
        'moneda': moneda,
        'tipo_pago': tipoPago,
        'titular': titular,
        'numero_cuenta': numeroCuenta,
        'descripcion': descripcion,
        'orden': orden,
        'activo': activo ? 1 : 0,
      };

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == '1' || text == 'true' || text == 'si' || text == 'sí';
  }
}
