import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_pedidos_controller.dart';
import '../../../core/platform/mood_platform.dart';
import '../../../models/admin/admin_pedido_model.dart';
import '../../../services/admin_pedidos_service.dart';
import '../../../services/mood_api_client.dart';

/// Vista para bodega/despacho.
/// Solo muestra pedidos enviados por contabilidad: estado_pedido_id = 3.
class DespachoPedidosPage extends StatefulWidget {
  final String? baseUrl;
  final Future<String?> Function() tokenProvider;

  const DespachoPedidosPage({
    super.key,
    required this.tokenProvider,
    this.baseUrl,
  });

  @override
  State<DespachoPedidosPage> createState() => _DespachoPedidosPageState();
}

class _DespachoPedidosPageState extends State<DespachoPedidosPage> {
  late final AdminPedidosController controller;

  @override
  void initState() {
    super.initState();
    final api = MoodApiClient(
      baseUrl: widget.baseUrl ?? MoodPlatformConfig.apiBaseUrl(),
      tokenProvider: widget.tokenProvider,
    );
    controller = AdminPedidosController(AdminPedidosService(api));
    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
    final message = controller.lastMessage;
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      controller.lastMessage = null;
    }
  }

  Future<void> _cargar() async {
    await controller.cargar(estadoPedidoId: 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bodega / Despacho')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: MoodPlatformConfig.pagePadding(context),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MoodPlatformConfig.maxContentWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedidos listos para despacho',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.loading)
                      const Center(child: CircularProgressIndicator())
                    else if (controller.error != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(controller.error!),
                        ),
                      )
                    else if (controller.pedidos.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No hay pedidos pendientes de bodega.')),
                        ),
                      )
                    else
                      ...controller.pedidos.map(
                        (pedido) => _DespachoPedidoCard(
                          pedido: pedido,
                          onDespachar: () => _confirmarDespacho(pedido),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarDespacho(AdminPedido pedido) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Despachar pedido'),
        content: Text('¿Confirmar despacho del pedido ${pedido.codigoPedido}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Despachar')),
        ],
      ),
    );

    if (ok == true) await controller.despachar(pedido.id);
  }
}

class _DespachoPedidoCard extends StatelessWidget {
  final AdminPedido pedido;
  final VoidCallback onDespachar;

  const _DespachoPedidoCard({
    required this.pedido,
    required this.onDespachar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                const Chip(label: Text('Pago aprobado')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${pedido.clienteCompleto}'),
            Text('Teléfono: ${pedido.telefonoCliente}'),
            Text('Zona: ${pedido.envioZonaNombre}'),
            Text('Total: C\$ ${pedido.totalFinal.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onDespachar,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Marcar como despachado'),
            ),
          ],
        ),
      ),
    );
  }
}
