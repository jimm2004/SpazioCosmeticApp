String _s(dynamic value) => value?.toString() ?? '';
int _i(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _d(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0.0;
bool _b(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == '1' || text == 'true' || text == 'si' || text == 'sí';
}

class MetodoPagoCheckout {
  final int id;
  final String tipoPago;
  final String banco;
  final String moneda;
  final String titular;
  final String numeroCuenta;
  final bool activo;

  const MetodoPagoCheckout({
    required this.id,
    required this.tipoPago,
    required this.banco,
    required this.moneda,
    required this.titular,
    required this.numeroCuenta,
    required this.activo,
  });

  String get etiqueta => '$banco $moneda - $titular'.trim();

  factory MetodoPagoCheckout.fromJson(Map<String, dynamic> json) {
    return MetodoPagoCheckout(
      id: _i(json['id']),
      tipoPago: _s(json['tipo_pago']).isEmpty ? 'transferencia' : _s(json['tipo_pago']),
      banco: _s(json['banco']),
      moneda: _s(json['moneda']),
      titular: _s(json['titular']),
      numeroCuenta: _s(json['numero_cuenta']),
      activo: _b(json['activo'] ?? true),
    );
  }
}

class PreviewEnvioCheckout {
  final int departamentoId;
  final int zonaId;
  final String zonaNombre;
  final double porcentajeEnvio;
  final double subtotal;
  final double costoEnvio;
  final double totalFinal;

  const PreviewEnvioCheckout({
    required this.departamentoId,
    required this.zonaId,
    required this.zonaNombre,
    required this.porcentajeEnvio,
    required this.subtotal,
    required this.costoEnvio,
    required this.totalFinal,
  });

  factory PreviewEnvioCheckout.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return PreviewEnvioCheckout(
      departamentoId: _i(data['departamento_id']),
      zonaId: _i(data['zona_id']),
      zonaNombre: _s(data['zona_nombre']),
      porcentajeEnvio: _d(data['porcentaje_envio']),
      subtotal: _d(data['subtotal']),
      costoEnvio: _d(data['costo_envio']),
      totalFinal: _d(data['total_final']),
    );
  }
}

class PedidoClienteResumen {
  final int id;
  final String codigoPedido;
  final int estadoPedidoId;
  final String estadoNombre;
  final String estadoPago;
  final double subtotal;
  final double costoEnvio;
  final double totalFinal;
  final String fechaPedido;

  const PedidoClienteResumen({
    required this.id,
    required this.codigoPedido,
    required this.estadoPedidoId,
    required this.estadoNombre,
    required this.estadoPago,
    required this.subtotal,
    required this.costoEnvio,
    required this.totalFinal,
    required this.fechaPedido,
  });

  factory PedidoClienteResumen.fromJson(Map<String, dynamic> json) {
    return PedidoClienteResumen(
      id: _i(json['id']),
      codigoPedido: _s(json['codigo_pedido']),
      estadoPedidoId: _i(json['estado_pedido_id']),
      estadoNombre: _s(json['estado_nombre']),
      estadoPago: _s(json['estado_pago']),
      subtotal: _d(json['subtotal']),
      costoEnvio: _d(json['costo_envio']),
      totalFinal: _d(json['total_final']),
      fechaPedido: _s(json['fecha_pedido']),
    );
  }
}
