String _s(dynamic value) => value?.toString() ?? '';
int _i(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _d(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0.0;

class AdminPedidosResumen {
  final int pendientesRevision;
  final int pagosAprobados;
  final int pagosRechazados;
  final int pendientesBodega;
  final int despachados;

  const AdminPedidosResumen({
    required this.pendientesRevision,
    required this.pagosAprobados,
    required this.pagosRechazados,
    required this.pendientesBodega,
    required this.despachados,
  });

  factory AdminPedidosResumen.fromJson(Map<String, dynamic>? json) {
    return AdminPedidosResumen(
      pendientesRevision: _i(json?['pendientes_revision']),
      pagosAprobados: _i(json?['pagos_aprobados']),
      pagosRechazados: _i(json?['pagos_rechazados']),
      pendientesBodega: _i(json?['pendientes_bodega']),
      despachados: _i(json?['despachados']),
    );
  }
}

class AdminPedido {
  final int id;
  final String codigoPedido;
  final int estadoPedidoId;
  final String estadoNombre;
  final String estadoPago;
  final String nombresCliente;
  final String apellidosCliente;
  final String telefonoCliente;
  final String bancoTransferencia;
  final String monedaPago;
  final String referenciaTransferencia;
  final String envioZonaNombre;
  final double envioPorcentaje;
  final double subtotal;
  final double costoEnvio;
  final double total;
  final double totalFinal;
  final String fechaPedido;
  final String? observacion;

  const AdminPedido({
    required this.id,
    required this.codigoPedido,
    required this.estadoPedidoId,
    required this.estadoNombre,
    required this.estadoPago,
    required this.nombresCliente,
    required this.apellidosCliente,
    required this.telefonoCliente,
    required this.bancoTransferencia,
    required this.monedaPago,
    required this.referenciaTransferencia,
    required this.envioZonaNombre,
    required this.envioPorcentaje,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    required this.totalFinal,
    required this.fechaPedido,
    this.observacion,
  });

  String get clienteCompleto => '$nombresCliente $apellidosCliente'.trim();

  factory AdminPedido.fromJson(Map<String, dynamic> json) {
    return AdminPedido(
      id: _i(json['id']),
      codigoPedido: _s(json['codigo_pedido']),
      estadoPedidoId: _i(json['estado_pedido_id']),
      estadoNombre: _s(json['estado_nombre']),
      estadoPago: _s(json['estado_pago']),
      nombresCliente: _s(json['nombres_cliente']),
      apellidosCliente: _s(json['apellidos_cliente']),
      telefonoCliente: _s(json['telefono_cliente']),
      bancoTransferencia: _s(json['banco_transferencia']),
      monedaPago: _s(json['moneda_pago']),
      referenciaTransferencia: _s(json['referencia_transferencia']),
      envioZonaNombre: _s(json['envio_zona_nombre']),
      envioPorcentaje: _d(json['envio_porcentaje']),
      subtotal: _d(json['subtotal']),
      costoEnvio: _d(json['costo_envio']),
      total: _d(json['total']),
      totalFinal: _d(json['total_final']),
      fechaPedido: _s(json['fecha_pedido']),
      observacion: json['observacion']?.toString(),
    );
  }
}

class AdminPedidoDetalle {
  final int id;
  final int productoMasterId;
  final int productoImagenId;
  final String nombreProducto;
  final double precioUnitario;
  final double precioFinal;
  final int cantidad;
  final double subtotal;
  final String imagenUrl;

  const AdminPedidoDetalle({
    required this.id,
    required this.productoMasterId,
    required this.productoImagenId,
    required this.nombreProducto,
    required this.precioUnitario,
    required this.precioFinal,
    required this.cantidad,
    required this.subtotal,
    required this.imagenUrl,
  });

  factory AdminPedidoDetalle.fromJson(Map<String, dynamic> json) {
    return AdminPedidoDetalle(
      id: _i(json['id']),
      productoMasterId: _i(json['producto_master_id']),
      productoImagenId: _i(json['producto_imagen_id']),
      nombreProducto: _s(json['nombre_producto']),
      precioUnitario: _d(json['precio_unitario']),
      precioFinal: _d(json['precio_final']),
      cantidad: _i(json['cantidad']),
      subtotal: _d(json['subtotal']),
      imagenUrl: _s(json['imagen_url']),
    );
  }
}

class AdminPedidoFull {
  final Map<String, dynamic> pedidoRaw;
  final List<AdminPedidoDetalle> detalles;

  const AdminPedidoFull({
    required this.pedidoRaw,
    required this.detalles,
  });

  factory AdminPedidoFull.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final pedido = data['pedido'] is Map<String, dynamic>
        ? data['pedido'] as Map<String, dynamic>
        : <String, dynamic>{};
    final detallesJson = data['detalles'] is List ? data['detalles'] as List : const [];

    return AdminPedidoFull(
      pedidoRaw: pedido,
      detalles: detallesJson
          .whereType<Map>()
          .map((e) => AdminPedidoDetalle.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class AdminPedidosResponse {
  final AdminPedidosResumen resumen;
  final List<AdminPedido> pedidos;

  const AdminPedidosResponse({
    required this.resumen,
    required this.pedidos,
  });

  factory AdminPedidosResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is List ? json['data'] as List : const [];
    return AdminPedidosResponse(
      resumen: AdminPedidosResumen.fromJson(
        json['resumen'] is Map<String, dynamic>
            ? json['resumen'] as Map<String, dynamic>
            : null,
      ),
      pedidos: data
          .whereType<Map>()
          .map((e) => AdminPedido.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
