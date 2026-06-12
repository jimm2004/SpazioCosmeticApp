import 'package:flutter/material.dart';

import '../../controllers/catalogo/pedidos_controller.dart';
import '../../models/catalogo/pedido_model.dart';
import 'mood_palette.dart';
import 'widgets/web_safe_network_image.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final PedidosController controller = PedidosController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
    controller.cargarPedidos();
  }

  @override
  void dispose() {
    controller.removeListener(_sync);
    controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  Future<void> _abrirDetalle(PedidoModel pedido) async {
    final detalle = await controller.verDetalle(pedido.id);
    if (!mounted || detalle == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PedidoDetalleSheet(controller: controller, pedido: detalle),
    );
  }

  Future<void> _cancelarPedido(PedidoModel pedido) async {
    if (!pedido.puedeCorregirReferencia) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cancelar pedido',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Text(
          'Se eliminará el pedido ${pedido.codigoPedido.isEmpty ? '#${pedido.id}' : pedido.codigoPedido}, '
          'se borrarán sus registros y se regresará el stock al inventario. ¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Sí, cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await controller.cancelarPedidoRechazado(pedidoId: pedido.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pedido cancelado. Se restauró el stock correctamente.'
              : controller.error ?? 'No se pudo cancelar el pedido.',
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoodPalette.background,
      appBar: AppBar(
        backgroundColor: MoodPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoodPalette.text),
        title: const Text('Mis pedidos', style: TextStyle(color: MoodPalette.text, fontWeight: FontWeight.w900)),
      ),
      body: controller.loading && controller.pedidos.isEmpty
          ? const Center(child: CircularProgressIndicator(color: MoodPalette.pink))
          : RefreshIndicator(
              color: MoodPalette.pink,
              onRefresh: controller.cargarPedidos,
              child: controller.pedidos.isEmpty
                  ? ListView(
                      cacheExtent: 160,
                      padding: const EdgeInsets.all(28),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.receipt_long_outlined, color: MoodPalette.pink, size: 78),
                        SizedBox(height: 14),
                        Text('Todavía no tenés pedidos', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        SizedBox(height: 6),
                        Text('Cuando confirmés un carrito, aparecerá aquí para seguimiento.', textAlign: TextAlign.center),
                      ],
                    )
                  : ListView.separated(
                      cacheExtent: 160,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      itemCount: controller.pedidos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final pedido = controller.pedidos[index];
                        return _PedidoCard(
                          pedido: pedido,
                          onTap: () => _abrirDetalle(pedido),
                          onCancelar: pedido.puedeCorregirReferencia
                              ? () => _cancelarPedido(pedido)
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class _PedidoCard extends StatelessWidget {
  final PedidoModel pedido;
  final VoidCallback onTap;
  final VoidCallback? onCancelar;

  const _PedidoCard({
    required this.pedido,
    required this.onTap,
    required this.onCancelar,
  });

  Color get _estadoColor {
    final pago = pedido.estadoPago.toLowerCase();
    if (pago.contains('rechaz')) return Colors.redAccent;
    if (pago.contains('aprob')) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.07)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(pedido.codigoPedido.isEmpty ? 'Pedido #${pedido.id}' : pedido.codigoPedido, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _estadoColor.withOpacity(.10), borderRadius: BorderRadius.circular(999)),
              child: Text(pedido.estadoPagoVisible, style: TextStyle(color: _estadoColor, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(pedido.estadoNombre, style: const TextStyle(color: MoodPalette.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.local_shipping_outlined, size: 18, color: MoodPalette.pink),
            const SizedBox(width: 6),
            Expanded(child: Text(pedido.envioZonaNombre.isEmpty ? 'Zona de envío registrada' : pedido.envioZonaNombre)),
            Text('C\$ ${pedido.totalFinal.toStringAsFixed(2)}', style: const TextStyle(color: MoodPalette.pink, fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
          if (pedido.puedeCorregirReferencia) ...[
            const SizedBox(height: 8),
            const Text(
              'Requiere corrección de referencia',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onCancelar,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Cancelar pedido'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _PedidoDetalleSheet extends StatefulWidget {
  final PedidosController controller;
  final PedidoModel pedido;
  const _PedidoDetalleSheet({required this.controller, required this.pedido});

  @override
  State<_PedidoDetalleSheet> createState() => _PedidoDetalleSheetState();
}

class _PedidoDetalleSheetState extends State<_PedidoDetalleSheet> {
  late PedidoModel pedido;
  final referenciaCtrl = TextEditingController();
  final observacionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    pedido = widget.pedido;
    referenciaCtrl.text = pedido.referenciaTransferencia;
  }

  @override
  void dispose() {
    referenciaCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _corregir() async {
    final ok = await widget.controller.corregirReferencia(
      pedidoId: pedido.id,
      referenciaTransferencia: referenciaCtrl.text,
      observacion: observacionCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Referencia enviada a revisión' : widget.controller.error ?? 'No se pudo corregir'), backgroundColor: ok ? Colors.green : Colors.redAccent),
    );
    if (ok && widget.controller.seleccionado != null) {
      setState(() => pedido = widget.controller.seleccionado!);
    }
  }

  Future<void> _cancelarPedidoRechazado() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cancelar pedido rechazado',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: Text(
          'Se eliminará este pedido, sus datos de pago y sus detalles. '
          'También se regresará al inventario la cantidad de productos reservada. '
          'Esta acción no se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Sí, cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await widget.controller.cancelarPedidoRechazado(pedidoId: pedido.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pedido cancelado. Stock restaurado correctamente.'
              : widget.controller.error ?? 'No se pudo cancelar el pedido.',
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
      ),
    );

    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .55,
      maxChildSize: .96,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(color: MoodPalette.background, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(18),
          children: [
            Center(child: Container(width: 52, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Text(pedido.codigoPedido.isEmpty ? 'Pedido #${pedido.id}' : pedido.codigoPedido, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
            _InfoCard(children: [
              _row('Estado pedido', pedido.estadoNombre),
              _row('Estado pago', pedido.estadoPagoVisible),
              if (pedido.motivoRechazoPago.isNotEmpty) _row('Motivo rechazo', pedido.motivoRechazoPago),
              _row('Subtotal', 'C\$ ${pedido.subtotal.toStringAsFixed(2)}'),
              _row('Envío', 'C\$ ${pedido.costoEnvio.toStringAsFixed(2)}'),
              _row('Total', 'C\$ ${pedido.totalFinal.toStringAsFixed(2)}', bold: true),
            ]),
            const SizedBox(height: 12),
            if (pedido.detalles.isNotEmpty) ...[
              const Text('Productos', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              ...pedido.detalles.map((d) => _DetalleProducto(detalle: d)),
            ],
            if (pedido.puedeCorregirReferencia) ...[
              const SizedBox(height: 12),
              _InfoCard(children: [
                const Text('Corregir referencia de transferencia', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 10),
                TextField(
                  controller: referenciaCtrl,
                  decoration: const InputDecoration(labelText: 'Nueva referencia', prefixIcon: Icon(Icons.receipt_long_rounded)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: observacionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Observación opcional', prefixIcon: Icon(Icons.notes_rounded)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: widget.controller.saving ? null : _corregir,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(widget.controller.saving ? 'Enviando...' : 'Enviar corrección'),
                  style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: widget.controller.saving ? null : _cancelarPedidoRechazado,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Cancelar pedido y devolver stock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ]),
            ],
            if (pedido.historial.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Historial', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 8),
              ...pedido.historial.map((h) => _HistorialTile(item: h)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label, style: const TextStyle(color: MoodPalette.muted, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700))),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [MoodPalette.cardShadow(.05)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );
}

class _DetalleProducto extends StatelessWidget {
  final PedidoDetalleModel detalle;
  const _DetalleProducto({required this.detalle});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [MoodPalette.cardShadow(.04)]),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: MoodPalette.softPink,
              child: detalle.imagenUrl.isEmpty ? const Icon(Icons.image_outlined) : WebSafeNetworkImage(url: detalle.imagenUrl, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(detalle.nombreProducto, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text('${detalle.cantidad} x C\$ ${detalle.precioFinal.toStringAsFixed(2)}', style: const TextStyle(color: MoodPalette.muted)),
        ]),
      );
}

class _HistorialTile extends StatelessWidget {
  final PedidoHistorialModel item;
  const _HistorialTile({required this.item});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.accion.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w900)),
          if (item.observacion.isNotEmpty) Text(item.observacion, style: const TextStyle(color: MoodPalette.muted)),
          if (item.createdAt.isNotEmpty) Text(item.createdAt, style: const TextStyle(fontSize: 12, color: MoodPalette.muted)),
        ]),
      );
}
