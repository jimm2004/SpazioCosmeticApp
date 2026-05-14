class PedidoModel {
  final int id;
  final String codigoPedido;
  final int estadoPedidoId;
  final String estadoNombre;
  final String estadoPago;
  final double subtotal;
  final double costoEnvio;
  final double total;
  final double totalFinal;
  final String fechaPedido;
  final String fechaEntrega;
  final String observacion;
  final String referenciaTransferencia;
  final String motivoRechazoPago;
  final String envioZonaNombre;
  final double envioPorcentaje;
  final Map<String, dynamic>? cliente;
  final Map<String, dynamic>? pago;
  final Map<String, dynamic>? envio;
  final List<PedidoDetalleModel> detalles;
  final List<PedidoHistorialModel> historial;

  const PedidoModel({
    required this.id,
    required this.codigoPedido,
    required this.estadoPedidoId,
    required this.estadoNombre,
    required this.estadoPago,
    required this.subtotal,
    required this.costoEnvio,
    required this.total,
    required this.totalFinal,
    required this.fechaPedido,
    this.fechaEntrega = '',
    this.observacion = '',
    this.referenciaTransferencia = '',
    this.motivoRechazoPago = '',
    this.envioZonaNombre = '',
    this.envioPorcentaje = 0,
    this.cliente,
    this.pago,
    this.envio,
    this.detalles = const [],
    this.historial = const [],
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final pagoMap = root['pago'] is Map ? Map<String, dynamic>.from(root['pago']) : null;
    final envioMap = root['envio'] is Map ? Map<String, dynamic>.from(root['envio']) : null;
    final clienteMap = root['cliente'] is Map ? Map<String, dynamic>.from(root['cliente']) : null;

    final rawDetalles = root['detalles'];
    final detalles = <PedidoDetalleModel>[];
    if (rawDetalles is List) {
      for (final item in rawDetalles) {
        if (item is Map) detalles.add(PedidoDetalleModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final rawHistorial = root['historial'];
    final historial = <PedidoHistorialModel>[];
    if (rawHistorial is List) {
      for (final item in rawHistorial) {
        if (item is Map) historial.add(PedidoHistorialModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    return PedidoModel(
      id: _toInt(root['id']),
      codigoPedido: _str(root['codigo_pedido']),
      estadoPedidoId: _toInt(root['estado_pedido_id']),
      estadoNombre: _str(root['estado_nombre']),
      estadoPago: _str(root['estado_pago'] ?? pagoMap?['estado_pago']),
      subtotal: _toDouble(root['subtotal']),
      costoEnvio: _toDouble(root['costo_envio']),
      total: _toDouble(root['total']),
      totalFinal: _toDouble(root['total_final'] ?? root['total']),
      fechaPedido: _str(root['fecha_pedido']),
      fechaEntrega: _str(root['fecha_entrega']),
      observacion: _str(root['observacion']),
      referenciaTransferencia: _str(root['referencia_transferencia'] ?? pagoMap?['referencia']),
      motivoRechazoPago: _str(root['motivo_rechazo_pago'] ?? pagoMap?['motivo_rechazo']),
      envioZonaNombre: _str(root['envio_zona_nombre'] ?? envioMap?['zona_nombre']),
      envioPorcentaje: _toDouble(root['envio_porcentaje'] ?? envioMap?['porcentaje']),
      cliente: clienteMap,
      pago: pagoMap,
      envio: envioMap,
      detalles: detalles,
      historial: historial,
    );
  }

  bool get puedeCorregirReferencia {
    final estado = estadoPago.toLowerCase().trim();
    return estado == 'rechazado' ||
        estado == 'rechazado_contabilidad' ||
        estado == 'referencia_rechazada' ||
        estado == 'correccion_requerida';
  }

  String get estadoPagoVisible {
    if (estadoPago.isEmpty) return 'Sin estado de pago';
    return estadoPago.replaceAll('_', ' ');
  }
}

class PedidoDetalleModel {
  final int id;
  final int productoMasterId;
  final int? productoImagenId;
  final String nombreProducto;
  final String imagenUrl;
  final double precioUnitario;
  final double precioFinal;
  final int cantidad;
  final double subtotal;

  const PedidoDetalleModel({
    required this.id,
    required this.productoMasterId,
    this.productoImagenId,
    required this.nombreProducto,
    required this.imagenUrl,
    required this.precioUnitario,
    required this.precioFinal,
    required this.cantidad,
    required this.subtotal,
  });

  factory PedidoDetalleModel.fromJson(Map<String, dynamic> json) => PedidoDetalleModel(
        id: _toInt(json['id']),
        productoMasterId: _toInt(json['producto_master_id']),
        productoImagenId: _toNullableInt(json['producto_imagen_id']),
        nombreProducto: _str(json['nombre_producto'] ?? json['nombre']),
        imagenUrl: _str(json['imagen_url']),
        precioUnitario: _toDouble(json['precio_unitario']),
        precioFinal: _toDouble(json['precio_final']),
        cantidad: _toInt(json['cantidad']),
        subtotal: _toDouble(json['subtotal']),
      );
}

class PedidoHistorialModel {
  final int id;
  final String accion;
  final String actorTipo;
  final String estadoPagoAnterior;
  final String estadoPagoNuevo;
  final String referenciaAnterior;
  final String referenciaNueva;
  final String observacion;
  final String createdAt;

  const PedidoHistorialModel({
    required this.id,
    required this.accion,
    required this.actorTipo,
    this.estadoPagoAnterior = '',
    this.estadoPagoNuevo = '',
    this.referenciaAnterior = '',
    this.referenciaNueva = '',
    this.observacion = '',
    this.createdAt = '',
  });

  factory PedidoHistorialModel.fromJson(Map<String, dynamic> json) => PedidoHistorialModel(
        id: _toInt(json['id']),
        accion: _str(json['accion']),
        actorTipo: _str(json['actor_tipo']),
        estadoPagoAnterior: _str(json['estado_pago_anterior']),
        estadoPagoNuevo: _str(json['estado_pago_nuevo']),
        referenciaAnterior: _str(json['referencia_anterior']),
        referenciaNueva: _str(json['referencia_nueva']),
        observacion: _str(json['observacion']),
        createdAt: _str(json['created_at']),
      );
}

String _str(dynamic value) => value?.toString() ?? '';

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}
