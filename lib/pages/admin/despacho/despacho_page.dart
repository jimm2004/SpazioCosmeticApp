import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_pedidos_controller.dart';
import '../../../models/admin/admin_pedido_model.dart';
import '../../../services/admin_pedidos_service.dart';
import '../../../services/api_service.dart';
import '../../../services/mood_api_client.dart';

class DespachoPage extends StatefulWidget {
  final AdminPedidosController? controller;

  const DespachoPage({
    super.key,
    this.controller,
  });

  @override
  State<DespachoPage> createState() => _DespachoPageState();
}

class _DespachoPageState extends State<DespachoPage> {
  late final AdminPedidosController controller;
  late final bool _controllerPropio;

  @override
  void initState() {
    super.initState();

    _controllerPropio = widget.controller == null;

    controller = widget.controller ??
        AdminPedidosController(
          AdminPedidosService(
            MoodApiClient(
              tokenProvider: () async {
                final token = ApiService().token;

                debugPrint(
                  'TOKEN DESPACHO DESDE ApiService: ${token != null && token.isNotEmpty}',
                );

                return token;
              },
            ),
          ),
        );

    controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.cargarPendientesDespacho();
    });
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);

    if (_controllerPropio) {
      controller.dispose();
    }

    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _recargar() {
    return controller.cargarPendientesDespacho();
  }

  Future<void> _confirmarDespacho(AdminPedido pedido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Confirmar despacho',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            '¿Deseás despachar el pedido ${pedido.codigoPedido}?\n\n'
            'Este pedido ya fue aprobado por contabilidad. Al confirmar, se marcará como despachado '
            'y la API enviará un correo al cliente registrado en la base de datos.',
          ),
          actions: [
            TextButton(
              onPressed: controller.loading
                  ? null
                  : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: controller.loading
                  ? null
                  : () => Navigator.pop(context, true),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Despachar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await controller.despachar(pedido.id);

    if (!mounted) return;

    final mensaje = controller.error ?? controller.lastMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje ?? 'Operación completada.'),
        backgroundColor: controller.error == null ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = controller.pedidos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despacho'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: controller.loading ? null : _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: _buildBody(pedidos),
      ),
    );
  }

  Widget _buildBody(List<AdminPedido> pedidos) {
    if (controller.loading && pedidos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.error != null && pedidos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _MensajeEstado(
            icon: Icons.error_outline,
            titulo: 'No se pudieron cargar los pedidos',
            descripcion: controller.error!,
          ),
        ],
      );
    }

    if (pedidos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          _MensajeEstado(
            icon: Icons.inventory_2_outlined,
            titulo: 'Sin pedidos para despacho',
            descripcion:
                'Cuando contabilidad apruebe una transferencia, el pedido aparecerá aquí.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: pedidos.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ResumenDespacho(
            totalPendientes: pedidos.length,
            loading: controller.loading,
          );
        }

        final pedido = pedidos[index - 1];

        return _PedidoDespachoCard(
          pedido: pedido,
          loading: controller.loading,
          onDespachar: () => _confirmarDespacho(pedido),
        );
      },
    );
  }
}

class _ResumenDespacho extends StatelessWidget {
  final int totalPendientes;
  final bool loading;

  const _ResumenDespacho({
    required this.totalPendientes,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.local_shipping_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pedidos listos para despacho: $totalPendientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _PedidoDespachoCard extends StatelessWidget {
  final AdminPedido pedido;
  final bool loading;
  final VoidCallback onDespachar;

  const _PedidoDespachoCard({
    required this.pedido,
    required this.loading,
    required this.onDespachar,
  });

  @override
  Widget build(BuildContext context) {
    final cliente =
        '${pedido.nombresCliente ?? ''} ${pedido.apellidosCliente ?? ''}'
            .trim();

    final puedeDespacharse =
        pedido.estadoPago == 'aprobado' && pedido.estadoPedidoId == 3;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pedido.codigoPedido,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _EstadoChip(
                  label: pedido.estadoPago ?? 'Sin pago',
                  color: puedeDespacharse ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cliente.isEmpty ? 'Cliente no disponible' : cliente,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Referencia: ${pedido.referenciaTransferencia ?? 'No disponible'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Total: ${pedido.totalFinal ?? pedido.total ?? '0.00'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              puedeDespacharse
                  ? 'Estado: aprobado por contabilidad y listo para despacho.'
                  : 'Estado: este pedido aún no está listo para despacho.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: puedeDespacharse ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Aprobado'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        loading || !puedeDespacharse ? null : onDespachar,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Despachar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _EstadoChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MensajeEstado extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descripcion;

  const _MensajeEstado({
    required this.icon,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 52),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                descripcion,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}