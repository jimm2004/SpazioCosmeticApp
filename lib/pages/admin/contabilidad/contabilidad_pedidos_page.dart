import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

class ContabilidadPedidosPage extends StatefulWidget {
  const ContabilidadPedidosPage({super.key});

  @override
  State<ContabilidadPedidosPage> createState() =>
      _ContabilidadPedidosPageState();
}

class _ContabilidadPedidosPageState extends State<ContabilidadPedidosPage> {
  bool loading = true;
  String? error;
  String filtro = '';
  String estadoPago = 'pendiente_revision';

  int? accionPedidoId;

  List<PedidoContableModel> pedidos = [];

  final TextEditingController buscarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarPedidos();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  List<PedidoContableModel> get pedidosFiltrados {
    final q = filtro.trim().toLowerCase();

    if (q.isEmpty) return pedidos;

    return pedidos.where((p) {
      return p.codigo.toLowerCase().contains(q) ||
          p.cliente.toLowerCase().contains(q) ||
          p.telefono.toLowerCase().contains(q) ||
          p.banco.toLowerCase().contains(q) ||
          p.referencia.toLowerCase().contains(q) ||
          p.moneda.toLowerCase().contains(q);
    }).toList();
  }

  double get montoTotalFiltrado {
    return pedidosFiltrados.fold<double>(
      0,
      (sum, p) => sum + p.totalFinal,
    );
  }

  String get endpointPedidos {
    if (estadoPago == 'todos') {
      return '/api/admin/pedidos';
    }

    return '/api/admin/pedidos?estado_pago=$estadoPago';
  }

  Future<void> cargarPedidos({bool mostrarMensaje = false}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get(endpointPedidos);
      final data = _extraerLista(res);

      if (!mounted) return;

      setState(() {
        pedidos = data
            .whereType<Map>()
            .map(
              (e) => PedidoContableModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      });

      if (mostrarMensaje) {
        _snack('Pedidos actualizados correctamente.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = _limpiarError(e);
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<dynamic> _extraerLista(Map<String, dynamic> res) {
    final data = res['data'];

    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }

    if (res['pedidos'] is List) {
      return res['pedidos'] as List;
    }

    return [];
  }

  Future<void> aprobarPedido(PedidoContableModel pedido) async {
    if (pedido.id <= 0) {
      _snack('No se encontró el ID del pedido.', error: true);
      return;
    }

    final confirmar = await _confirmarAccion(
      titulo: 'Aprobar transferencia',
      mensaje:
          '¿Confirmás aprobar la transferencia del pedido ${pedido.codigo}?\n\n'
          'Cliente: ${pedido.clienteVisible}\n'
          'Monto: ${pedido.moneda} ${pedido.totalFinal.toStringAsFixed(2)}\n\n'
          'Después de aprobar, el pedido pasará a bodega.',
      icon: Icons.check_circle_rounded,
      color: Colors.green,
      textoBoton: 'Aprobar',
    );

    if (confirmar != true) return;

    setState(() => accionPedidoId = pedido.id);

    try {
      await ApiService().post(
        '/api/admin/pedidos/${pedido.id}/aprobar-transferencia',
      );

      _snack(
        'Transferencia aprobada. Pedido enviado a bodega.',
        icon: Icons.check_circle_rounded,
      );

      await cargarPedidos();
    } catch (e) {
      _snack(_limpiarError(e), error: true);
    } finally {
      if (mounted) {
        setState(() => accionPedidoId = null);
      }
    }
  }

  Future<void> rechazarPedido(PedidoContableModel pedido) async {
    if (pedido.id <= 0) {
      _snack('No se encontró el ID del pedido.', error: true);
      return;
    }

    final motivo = await _pedirMotivoRechazo(pedido);

    if (motivo == null) return;

    setState(() => accionPedidoId = pedido.id);

    try {
      await ApiService().post(
        '/api/admin/pedidos/${pedido.id}/rechazar-transferencia',
        body: {
          'motivo': motivo,
        },
      );

      _snack(
        'Transferencia rechazada correctamente.',
        error: true,
        icon: Icons.cancel_rounded,
      );

      await cargarPedidos();
    } catch (e) {
      _snack(_limpiarError(e), error: true);
    } finally {
      if (mounted) {
        setState(() => accionPedidoId = null);
      }
    }
  }

  Future<bool?> _confirmarAccion({
    required String titulo,
    required String mensaje,
    required IconData icon,
    required Color color,
    required String textoBoton,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            mensaje,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(icon),
              label: Text(textoBoton),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _pedirMotivoRechazo(PedidoContableModel pedido) async {
    final controller = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (_) {
        bool validar = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            final texto = controller.text.trim();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.redAccent.withAlpha(25),
                    child: const Icon(
                      Icons.cancel_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rechazar transferencia',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido: ${pedido.codigo}\n'
                    'Cliente: ${pedido.clienteVisible}\n'
                    'Monto: ${pedido.moneda} ${pedido.totalFinal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    onChanged: (_) => setLocalState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Motivo del rechazo',
                      hintText: 'Ejemplo: referencia no coincide...',
                      filled: true,
                      fillColor: const Color(0xFFF4F6FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      errorText:
                          validar && texto.isEmpty ? 'El motivo es obligatorio' : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setLocalState(() => validar = true);
                      return;
                    }

                    Navigator.pop(context, controller.text.trim());
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Rechazar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return motivo;
  }

  void verDetallePedido(PedidoContableModel pedido) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DetallePedidoSheet(
          pedido: pedido,
          procesando: accionPedidoId == pedido.id,
          onAprobar: pedido.estadoPago == 'pendiente_revision'
              ? () {
                  Navigator.pop(context);
                  aprobarPedido(pedido);
                }
              : null,
          onRechazar: pedido.estadoPago == 'pendiente_revision'
              ? () {
                  Navigator.pop(context);
                  rechazarPedido(pedido);
                }
              : null,
        );
      },
    );
  }

  void cambiarFiltroEstado(String value) {
    if (estadoPago == value) return;

    setState(() {
      estadoPago = value;
      buscarController.clear();
      filtro = '';
    });

    cargarPedidos();
  }

  String _limpiarError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _snack(
    String message, {
    bool error = false,
    IconData? icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              icon ?? (error ? Icons.error_outline_rounded : Icons.check),
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: const Text(
          'Revisión de pagos',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar pedidos',
            onPressed: loading
                ? null
                : () => cargarPedidos(mostrarMensaje: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: loading
            ? const _LoadingState()
            : error != null
                ? _ErrorState(
                    message: error!,
                    onRetry: cargarPedidos,
                  )
                : RefreshIndicator(
                    onRefresh: () => cargarPedidos(mostrarMensaje: true),
                    color: const Color(0xFFE91E63),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isDesktop = width >= 1100;
                        final isTablet = width >= 720 && width < 1100;

                        int crossAxisCount = 1;
                        double ratio = 1.18;

                        if (isDesktop) {
                          crossAxisCount = 3;
                          ratio = 1.24;
                        } else if (isTablet) {
                          crossAxisCount = 2;
                          ratio = 1.12;
                        }

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: _HeroContabilidadPedidos(
                                  totalPedidos: pedidosFiltrados.length,
                                  montoTotal: montoTotalFiltrado,
                                  estadoPago: estadoPago,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: _EstadoFilterBar(
                                  selected: estadoPago,
                                  onChanged: cambiarFiltroEstado,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: _SearchBox(
                                  controller: buscarController,
                                  onChanged: (value) {
                                    setState(() => filtro = value);
                                  },
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: _MetricsRow(
                                  pedidos: pedidosFiltrados,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                            if (pedidosFiltrados.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final pedido = pedidosFiltrados[index];
                                      final procesando =
                                          accionPedidoId == pedido.id;

                                      return _AnimatedPedidoCard(
                                        delay: index * 50,
                                        child: _PedidoCard(
                                          pedido: pedido,
                                          procesando: procesando,
                                          onDetalle: () =>
                                              verDetallePedido(pedido),
                                          onAprobar:
                                              pedido.estadoPago ==
                                                      'pendiente_revision'
                                                  ? () => aprobarPedido(pedido)
                                                  : null,
                                          onRechazar:
                                              pedido.estadoPago ==
                                                      'pendiente_revision'
                                                  ? () => rechazarPedido(pedido)
                                                  : null,
                                        ),
                                      );
                                    },
                                    childCount: pedidosFiltrados.length,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: ratio,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class PedidoContableModel {
  final int id;
  final String codigo;
  final String estadoPago;
  final String estadoPedido;
  final String nombresCliente;
  final String apellidosCliente;
  final String telefono;
  final String banco;
  final String moneda;
  final String referencia;
  final String zona;
  final double porcentajeEnvio;
  final double subtotal;
  final double costoEnvio;
  final double totalFinal;
  final String fechaPedido;

  const PedidoContableModel({
    required this.id,
    required this.codigo,
    required this.estadoPago,
    required this.estadoPedido,
    required this.nombresCliente,
    required this.apellidosCliente,
    required this.telefono,
    required this.banco,
    required this.moneda,
    required this.referencia,
    required this.zona,
    required this.porcentajeEnvio,
    required this.subtotal,
    required this.costoEnvio,
    required this.totalFinal,
    required this.fechaPedido,
  });

  factory PedidoContableModel.fromJson(Map<String, dynamic> json) {
    return PedidoContableModel(
      id: int.tryParse('${json['id']}') ?? 0,
      codigo: '${json['codigo_pedido'] ?? 'Sin código'}',
      estadoPago: '${json['estado_pago'] ?? 'pendiente_revision'}',
      estadoPedido: '${json['estado_nombre'] ?? ''}',
      nombresCliente: '${json['nombres_cliente'] ?? ''}',
      apellidosCliente: '${json['apellidos_cliente'] ?? ''}',
      telefono: '${json['telefono_cliente'] ?? ''}',
      banco: '${json['banco_transferencia'] ?? 'N/D'}',
      moneda: '${json['moneda_pago'] ?? 'C\$'}',
      referencia: '${json['referencia_transferencia'] ?? 'N/D'}',
      zona: '${json['envio_zona_nombre'] ?? 'N/D'}',
      porcentajeEnvio:
          double.tryParse('${json['envio_porcentaje'] ?? '0'}') ?? 0,
      subtotal: double.tryParse('${json['subtotal'] ?? '0'}') ?? 0,
      costoEnvio: double.tryParse('${json['costo_envio'] ?? '0'}') ?? 0,
      totalFinal: double.tryParse('${json['total_final'] ?? '0'}') ?? 0,
      fechaPedido: '${json['fecha_pedido'] ?? ''}',
    );
  }

  String get cliente {
    return '$nombresCliente $apellidosCliente'.trim();
  }

  String get clienteVisible {
    return cliente.isEmpty ? 'Cliente no disponible' : cliente;
  }

  Color get estadoColor {
    switch (estadoPago) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.redAccent;
      default:
        return const Color(0xFFE91E63);
    }
  }

  String get estadoLabel {
    switch (estadoPago) {
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'Pendiente';
    }
  }

  IconData get estadoIcon {
    switch (estadoPago) {
      case 'aprobado':
        return Icons.check_circle_rounded;
      case 'rechazado':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }
}

class _HeroContabilidadPedidos extends StatelessWidget {
  final int totalPedidos;
  final double montoTotal;
  final String estadoPago;

  const _HeroContabilidadPedidos({
    required this.totalPedidos,
    required this.montoTotal,
    required this.estadoPago,
  });

  @override
  Widget build(BuildContext context) {
    final estadoTexto = switch (estadoPago) {
      'aprobado' => 'pagos aprobados',
      'rechazado' => 'pagos rechazados',
      'todos' => 'todos los pagos',
      _ => 'pagos pendientes',
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF15172B),
            Color(0xFF5E35B1),
            Color(0xFFE91E63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(50),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white.withAlpha(25),
              size: 145,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Control contable de pedidos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Revisa transferencias, valida referencias y envía pedidos aprobados a bodega.',
                style: TextStyle(
                  color: Colors.white.withAlpha(210),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroPill(
                    icon: Icons.list_alt_rounded,
                    text: '$totalPedidos $estadoTexto',
                  ),
                  _HeroPill(
                    icon: Icons.payments_rounded,
                    text: 'Total: ${montoTotal.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _EstadoFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _FilterItem(
        value: 'pendiente_revision',
        label: 'Pendientes',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFE91E63),
      ),
      _FilterItem(
        value: 'aprobado',
        label: 'Aprobados',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      _FilterItem(
        value: 'rechazado',
        label: 'Rechazados',
        icon: Icons.cancel_rounded,
        color: Colors.redAccent,
      ),
      _FilterItem(
        value: 'todos',
        label: 'Todos',
        icon: Icons.all_inbox_rounded,
        color: const Color(0xFF5E35B1),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final active = selected == item.value;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: ChoiceChip(
                selected: active,
                avatar: Icon(
                  item.icon,
                  size: 18,
                  color: active ? Colors.white : item.color,
                ),
                selectedColor: item.color,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: active ? item.color : Colors.grey.shade200,
                ),
                label: Text(
                  item.label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF2C3E50),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onSelected: (_) => onChanged(item.value),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por cliente, pedido, teléfono, banco o referencia',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final List<PedidoContableModel> pedidos;

  const _MetricsRow({
    required this.pedidos,
  });

  @override
  Widget build(BuildContext context) {
    final total = pedidos.length;
    final monto = pedidos.fold<double>(0, (sum, p) => sum + p.totalFinal);
    final pendientes = pedidos.where((p) => p.estadoPago == 'pendiente_revision').length;
    final aprobados = pedidos.where((p) => p.estadoPago == 'aprobado').length;

    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < 720;

        final cards = [
          _MetricCard(
            icon: Icons.receipt_long_rounded,
            title: 'Pedidos',
            value: '$total',
            color: const Color(0xFF5E35B1),
          ),
          _MetricCard(
            icon: Icons.payments_rounded,
            title: 'Monto',
            value: monto.toStringAsFixed(2),
            color: const Color(0xFFE91E63),
          ),
          _MetricCard(
            icon: Icons.schedule_rounded,
            title: 'Pendientes',
            value: '$pendientes',
            color: Colors.orange,
          ),
          _MetricCard(
            icon: Icons.check_circle_rounded,
            title: 'Aprobados',
            value: '$aprobados',
            color: Colors.green,
          ),
        ];

        if (narrow) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(24),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPedidoCard extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedPedidoCard({
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay.clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _PedidoCard extends StatefulWidget {
  final PedidoContableModel pedido;
  final bool procesando;
  final VoidCallback onDetalle;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;

  const _PedidoCard({
    required this.pedido,
    required this.procesando,
    required this.onDetalle,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, hover ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hover ? p.estadoColor.withAlpha(90) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: hover
                  ? p.estadoColor.withAlpha(35)
                  : Colors.black.withAlpha(8),
              blurRadius: hover ? 20 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onDetalle,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: p.estadoColor.withAlpha(22),
                      child: Icon(
                        p.estadoIcon,
                        color: p.estadoColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.codigo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusBadge(pedido: p),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.person_rounded,
                  label: p.clienteVisible,
                ),
                _InfoLine(
                  icon: Icons.phone_rounded,
                  label: p.telefono.isEmpty ? 'Sin teléfono' : p.telefono,
                ),
                _InfoLine(
                  icon: Icons.account_balance_rounded,
                  label: '${p.banco} · ${p.moneda}',
                ),
                _InfoLine(
                  icon: Icons.numbers_rounded,
                  label: 'Ref: ${p.referencia}',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${p.moneda} ${p.totalFinal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.procesando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onRechazar,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onAprobar,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PedidoContableModel pedido;

  const _StatusBadge({
    required this.pedido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: pedido.estadoColor.withAlpha(22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        pedido.estadoLabel,
        style: TextStyle(
          color: pedido.estadoColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoLine({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetallePedidoSheet extends StatelessWidget {
  final PedidoContableModel pedido;
  final bool procesando;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;

  const _DetallePedidoSheet({
    required this.pedido,
    required this.procesando,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FB),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: pedido.estadoColor.withAlpha(25),
                      child: Icon(
                        pedido.estadoIcon,
                        color: pedido.estadoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pedido.codigo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetalleCard(
                  title: 'Cliente',
                  children: [
                    _DetalleItem('Nombre', pedido.clienteVisible),
                    _DetalleItem(
                      'Teléfono',
                      pedido.telefono.isEmpty ? 'N/D' : pedido.telefono,
                    ),
                    _DetalleItem(
                      'Fecha',
                      pedido.fechaPedido.isEmpty ? 'N/D' : pedido.fechaPedido,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetalleCard(
                  title: 'Pago',
                  children: [
                    _DetalleItem('Estado', pedido.estadoLabel),
                    _DetalleItem('Banco', pedido.banco),
                    _DetalleItem('Moneda', pedido.moneda),
                    _DetalleItem('Referencia', pedido.referencia),
                  ],
                ),
                const SizedBox(height: 12),
                _DetalleCard(
                  title: 'Totales',
                  children: [
                    _DetalleItem(
                      'Subtotal',
                      '${pedido.moneda} ${pedido.subtotal.toStringAsFixed(2)}',
                    ),
                    _DetalleItem(
                      'Envío',
                      '${pedido.moneda} ${pedido.costoEnvio.toStringAsFixed(2)}',
                    ),
                    _DetalleItem(
                      'Total final',
                      '${pedido.moneda} ${pedido.totalFinal.toStringAsFixed(2)}',
                    ),
                    _DetalleItem(
                      'Zona',
                      '${pedido.zona} (${pedido.porcentajeEnvio.toStringAsFixed(2)}%)',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (procesando)
                  const CircularProgressIndicator()
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRechazar,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAprobar,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetalleCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetalleCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetalleItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetalleItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFE91E63),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0, 1),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 74,
                color: Colors.green,
              ),
              SizedBox(height: 16),
              Text(
                'No hay pagos para mostrar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Todo está al día según el filtro seleccionado.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withAlpha(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 14),
            const Text(
              'No se pudieron cargar los pedidos',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}