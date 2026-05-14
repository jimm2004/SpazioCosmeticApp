import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_pedidos_controller.dart';
import '../../../models/admin/admin_pedido_model.dart';
import '../../../models/admin/despacho_documento_model.dart';
import '../../../services/admin_pedidos_service.dart';
import '../../../services/api_service.dart';
import '../../../services/despacho_pdf_service.dart';
import '../../../services/mood_api_client.dart';
import 'widgets/despacho_preview_sheet.dart';

const _moodPurple = Color(0xFF5E35B1);
const _moodText = Color(0xFF2C3E50);
const _moodBg = Color(0xFFF5F7FA);

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
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();

    _controllerPropio = widget.controller == null;

    controller = widget.controller ??
        AdminPedidosController(
          AdminPedidosService(
            MoodApiClient(
              tokenProvider: () async => ApiService().token,
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
    if (_controllerPropio) controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _recargar() => controller.cargarPendientesDespacho();

  Future<void> _abrirVistaDespacho(AdminPedido pedido) async {
    _notify('Preparando vista de despacho para ${pedido.codigoPedido}...', type: _NoticeType.info);

    final documento = await controller.prepararDocumentoDespacho(pedido.id);
    if (!mounted) return;

    if (documento == null) {
      _notify(controller.error ?? 'No se pudo preparar el despacho.', type: _NoticeType.error);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DespachoPreviewSheet(
        documento: documento,
        loading: controller.loading || _actionBusy,
        onPreviewPdf: () => _previewPdf(documento),
        onSharePdf: () => _sharePdf(documento),
        onConfirmDispatch: () => _confirmarDespachoDesdePreview(documento),
      ),
    );
  }

  Future<void> _previewPdf(DespachoDocumentoData documento) async {
    try {
      await DespachoPdfService.previewPdf(documento);
    } catch (e) {
      if (!mounted) return;
      _notify('No se pudo abrir el PDF: ${_cleanError(e)}', type: _NoticeType.error);
    }
  }

  Future<void> _sharePdf(DespachoDocumentoData documento) async {
    try {
      await DespachoPdfService.sharePdf(documento);
      if (!mounted) return;
      _notify('PDF generado: ${DespachoPdfService.fileName(documento)}', type: _NoticeType.success);
    } catch (e) {
      if (!mounted) return;
      _notify('No se pudo generar el PDF: ${_cleanError(e)}', type: _NoticeType.error);
    }
  }

  Future<void> _confirmarDespachoDesdePreview(DespachoDocumentoData documento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Confirmar despacho', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Se marcará como despachado el pedido ${documento.codigoPedido}.\n\n'
          'También se generará el PDF de control con los datos del cliente y productos a despachar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.local_shipping_rounded),
            label: const Text('Despachar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _actionBusy = true);
    await controller.despachar(documento.pedidoId);
    if (!mounted) return;

    setState(() => _actionBusy = false);

    if (controller.error != null) {
      _notify(controller.error!, type: _NoticeType.error);
      return;
    }

    _notify(controller.lastMessage ?? 'Pedido despachado correctamente.', type: _NoticeType.success);

    try {
      await DespachoPdfService.sharePdf(documento);
    } catch (e) {
      if (!mounted) return;
      _notify('El pedido se despachó, pero no se pudo abrir el PDF: ${_cleanError(e)}', type: _NoticeType.warning);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = controller.pedidos;

    return Scaffold(
      backgroundColor: _moodBg,
      appBar: AppBar(
        backgroundColor: _moodBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _moodText),
        title: const Text('Despacho', style: TextStyle(color: _moodText, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: controller.loading ? null : _recargar,
            icon: const Icon(Icons.refresh_rounded, color: _moodPurple),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: _moodPurple,
        onRefresh: _recargar,
        child: _buildBody(pedidos),
      ),
    );
  }

  Widget _buildBody(List<AdminPedido> pedidos) {
    if (controller.loading && pedidos.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _moodPurple));
    }

    if (controller.error != null && pedidos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _MensajeEstado(icon: Icons.error_outline, titulo: 'No se pudieron cargar los pedidos', descripcion: controller.error!),
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
            descripcion: 'Cuando contabilidad apruebe una transferencia, el pedido aparecerá aquí.',
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final maxWidth = isWide ? 1180.0 : 720.0;
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 16, isWide ? 28 : 16, 28),
          itemCount: pedidos.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: index == 0
                    ? _ResumenDespacho(totalPendientes: pedidos.length, loading: controller.loading || controller.preparingDespacho)
                    : _PedidoDespachoCard(
                        pedido: pedidos[index - 1],
                        loading: controller.loading || controller.preparingDespacho || _actionBusy,
                        onPreparar: () => _abrirVistaDespacho(pedidos[index - 1]),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _notify(String message, {required _NoticeType type}) {
    if (!mounted) return;
    final color = switch (type) {
      _NoticeType.success => Colors.green.shade700,
      _NoticeType.error => Colors.redAccent,
      _NoticeType.warning => Colors.orange.shade800,
      _NoticeType.info => _moodText,
    };
    final icon = switch (type) {
      _NoticeType.success => Icons.check_circle_rounded,
      _NoticeType.error => Icons.error_rounded,
      _NoticeType.warning => Icons.warning_amber_rounded,
      _NoticeType.info => Icons.info_rounded,
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)))]),
      ),
    );
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}

class _ResumenDespacho extends StatelessWidget {
  final int totalPendientes;
  final bool loading;

  const _ResumenDespacho({required this.totalPendientes, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_moodPurple, Color(0xFF7E57C2)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _moodPurple.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 9))],
      ),
      child: Row(
        children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedidos listos para despacho', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('$totalPendientes pedidos aprobados por contabilidad. Abrí la vista previa antes de confirmar.', style: TextStyle(color: Colors.white.withOpacity(0.86), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (loading) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        ],
      ),
    );
  }
}

class _PedidoDespachoCard extends StatelessWidget {
  final AdminPedido pedido;
  final bool loading;
  final VoidCallback onPreparar;

  const _PedidoDespachoCard({required this.pedido, required this.loading, required this.onPreparar});

  @override
  Widget build(BuildContext context) {
    final cliente = '${pedido.nombresCliente ?? ''} ${pedido.apellidosCliente ?? ''}'.trim();
    final puedeDespacharse = pedido.estadoPago == 'aprobado' && pedido.estadoPedidoId == 3;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(pedido.codigoPedido, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: _moodText))),
            _EstadoChip(label: pedido.estadoPago ?? 'Sin pago', color: puedeDespacharse ? Colors.green : Colors.orange),
          ]),
          const SizedBox(height: 10),
          Text(cliente.isEmpty ? 'Cliente no disponible' : cliente, style: const TextStyle(fontWeight: FontWeight.w700, color: _moodText)),
          const SizedBox(height: 4),
          Text('Referencia: ${pedido.referenciaTransferencia ?? 'No disponible'}', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text('Total: C\$ ${_money(pedido.totalFinal ?? pedido.total ?? 0)}', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.verified_outlined), label: const Text('Aprobado'))),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: loading || !puedeDespacharse ? null : onPreparar,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Ver despacho'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _money(dynamic value) {
    if (value is num) return value.toStringAsFixed(2);
    final parsed = double.tryParse(value.toString());
    return (parsed ?? 0).toStringAsFixed(2);
  }
}

class _EstadoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _EstadoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), backgroundColor: color, visualDensity: VisualDensity.compact);
  }
}

class _MensajeEstado extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descripcion;

  const _MensajeEstado({required this.icon, required this.titulo, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: Colors.grey.shade100)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(icon, size: 52, color: _moodPurple),
            const SizedBox(height: 12),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(descripcion, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

enum _NoticeType { success, error, warning, info }
