class DespachoDocumentoData {
  final int pedidoId;
  final String codigoPedido;
  final String estadoPago;
  final int estadoPedidoId;
  final String estadoNombre;
  final String clienteNombre;
  final String clienteEmail;
  final String clienteUsuario;
  final String telefono;
  final String direccion;
  final String departamento;
  final String municipio;
  final String referenciaDireccion;
  final String zonaEnvio;
  final String referenciaTransferencia;
  final String bancoTransferencia;
  final String monedaPago;
  final String fechaPedido;
  final String fechaEntrega;
  final String observacion;
  final double subtotal;
  final double costoEnvio;
  final double descuento;
  final double impuesto;
  final double total;
  final double totalFinal;
  final List<DespachoDocumentoItem> items;

  const DespachoDocumentoData({
    required this.pedidoId,
    required this.codigoPedido,
    required this.estadoPago,
    required this.estadoPedidoId,
    required this.estadoNombre,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.clienteUsuario,
    required this.telefono,
    required this.direccion,
    required this.departamento,
    required this.municipio,
    required this.referenciaDireccion,
    required this.zonaEnvio,
    required this.referenciaTransferencia,
    required this.bancoTransferencia,
    required this.monedaPago,
    required this.fechaPedido,
    required this.fechaEntrega,
    required this.observacion,
    required this.subtotal,
    required this.costoEnvio,
    required this.descuento,
    required this.impuesto,
    required this.total,
    required this.totalFinal,
    required this.items,
  });

  String get clienteVisible {
    if (clienteNombre.trim().isNotEmpty) return clienteNombre.trim();
    if (clienteUsuario.trim().isNotEmpty) return clienteUsuario.trim();
    return 'Cliente no disponible';
  }

  String get telefonoVisible => telefono.trim().isEmpty ? 'No disponible' : telefono.trim();
  String get direccionVisible => direccion.trim().isEmpty ? 'No disponible' : direccion.trim();
  String get zonaVisible => zonaEnvio.trim().isEmpty ? 'No disponible' : zonaEnvio.trim();
  String get correoVisible => clienteEmail.trim().isEmpty ? 'No disponible' : clienteEmail.trim();
  String get referenciaVisible => referenciaTransferencia.trim().isEmpty ? 'No disponible' : referenciaTransferencia.trim();

  int get totalUnidades => items.fold<int>(0, (sum, item) => sum + item.cantidad);

  bool get puedeDespacharse => estadoPago == 'aprobado' && estadoPedidoId == 3;

  static DespachoDocumentoData fromAdminPedidoApi(Map<String, dynamic> response) {
    final root = _asMap(response['data'] ?? response);
    final pedido = _asMap(root['pedido'] ?? root);
    final detallesRaw = root['detalles'];
    final detalles = detallesRaw is List ? detallesRaw : const [];

    final nombres = _str(pedido['nombres_cliente']);
    final apellidos = _str(pedido['apellidos_cliente']);
    final clienteNombre = '$nombres $apellidos'.trim();

    final items = detalles
        .where((item) => item is Map)
        .map((item) => DespachoDocumentoItem.fromJson(_asMap(item)))
        .toList();

    return DespachoDocumentoData(
      pedidoId: _int(pedido['id']),
      codigoPedido: _str(pedido['codigo_pedido'], fallback: 'PEDIDO-${_int(pedido['id'])}'),
      estadoPago: _str(pedido['estado_pago']).toLowerCase(),
      estadoPedidoId: _int(pedido['estado_pedido_id']),
      estadoNombre: _str(pedido['estado_nombre'], fallback: 'Pendiente'),
      clienteNombre: clienteNombre,
      clienteEmail: _str(pedido['cliente_email']),
      clienteUsuario: _str(pedido['cliente_usuario']),
      telefono: _str(pedido['telefono_contacto'] ?? pedido['telefono_cliente']),
      direccion: _str(pedido['direccion_entrega'] ?? pedido['direccion_cliente']),
      departamento: _str(pedido['departamento_nombre']),
      municipio: _str(pedido['municipio_nombre']),
      referenciaDireccion: _str(pedido['referencia_direccion']),
      zonaEnvio: _str(pedido['envio_zona_nombre']),
      referenciaTransferencia: _str(pedido['referencia_transferencia']),
      bancoTransferencia: _str(pedido['banco_transferencia'] ?? pedido['metodo_banco']),
      monedaPago: _str(pedido['moneda_pago'] ?? pedido['metodo_moneda'], fallback: 'C\$'),
      fechaPedido: _str(pedido['fecha_pedido']),
      fechaEntrega: _str(pedido['fecha_entrega']),
      observacion: _str(pedido['observacion']),
      subtotal: _double(pedido['subtotal']),
      costoEnvio: _double(pedido['costo_envio']),
      descuento: _double(pedido['descuento']),
      impuesto: _double(pedido['impuesto']),
      total: _double(pedido['total']),
      totalFinal: _double(pedido['total_final'] ?? pedido['total']),
      items: items,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _str(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  static int _int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _double(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    final clean = value.toString().replaceAll('C\$', '').replaceAll('\$', '').replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0;
  }
}

class DespachoDocumentoItem {
  final int id;
  final int productoId;
  final int productoImagenId;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final int cantidad;
  final double precioUnitario;
  final double precioFinal;
  final double subtotal;

  const DespachoDocumentoItem({
    required this.id,
    required this.productoId,
    required this.productoImagenId,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.cantidad,
    required this.precioUnitario,
    required this.precioFinal,
    required this.subtotal,
  });

  factory DespachoDocumentoItem.fromJson(Map<String, dynamic> json) {
    final cantidad = DespachoDocumentoData._int(json['cantidad']);
    final precioFinal = DespachoDocumentoData._double(
      json['precio_final'] ?? json['precio_unitario'] ?? json['precio'] ?? json['precio_venta'],
    );
    final subtotal = DespachoDocumentoData._double(
      json['subtotal'] ?? json['total'] ?? (cantidad * precioFinal),
    );

    return DespachoDocumentoItem(
      id: DespachoDocumentoData._int(json['id']),
      productoId: DespachoDocumentoData._int(
        json['producto_id'] ?? json['producto_master_id'] ?? json['id_producto'],
      ),
      productoImagenId: DespachoDocumentoData._int(json['producto_imagen_id'] ?? json['imagen_id']),
      nombre: DespachoDocumentoData._str(
        json['nombre_producto'] ?? json['producto_nombre'] ?? json['nombre'] ?? json['descripcion'],
        fallback: 'Producto sin nombre',
      ),
      descripcion: DespachoDocumentoData._str(json['descripcion'] ?? json['detalle']),
      imagenUrl: DespachoDocumentoData._str(json['imagen_url'] ?? json['img'] ?? json['imagen']),
      cantidad: cantidad,
      precioUnitario: DespachoDocumentoData._double(json['precio_unitario'] ?? json['precio'] ?? json['precio_venta']),
      precioFinal: precioFinal,
      subtotal: subtotal,
    );
  }
}
