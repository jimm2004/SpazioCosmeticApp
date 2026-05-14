import 'package:flutter/material.dart';

import '../../../../models/admin/despacho_documento_model.dart';

const _moodPurple = Color(0xFF5E35B1);
const _moodText = Color(0xFF2C3E50);
const _moodBg = Color(0xFFF5F7FA);

class DespachoPreviewSheet extends StatelessWidget {
  final DespachoDocumentoData documento;
  final bool loading;
  final VoidCallback onPreviewPdf;
  final VoidCallback onSharePdf;
  final VoidCallback onConfirmDispatch;

  const DespachoPreviewSheet({
    super.key,
    required this.documento,
    required this.loading,
    required this.onPreviewPdf,
    required this.onSharePdf,
    required this.onConfirmDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return DraggableScrollableSheet(
      initialChildSize: isWide ? 0.92 : 0.94,
      minChildSize: 0.60,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: _moodBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(isWide ? 34 : 18, 18, isWide ? 34 : 18, 26),
                  children: [
                    _Header(documento: documento),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ClienteCard(documento: documento)),
                          const SizedBox(width: 16),
                          Expanded(child: _ResumenCard(documento: documento)),
                        ],
                      )
                    else ...[
                      _ClienteCard(documento: documento),
                      const SizedBox(height: 14),
                      _ResumenCard(documento: documento),
                    ],
                    const SizedBox(height: 16),
                    _ProductosCard(documento: documento),
                    const SizedBox(height: 16),
                    _ActionBar(
                      loading: loading,
                      puedeDespacharse: documento.puedeDespacharse,
                      onPreviewPdf: onPreviewPdf,
                      onSharePdf: onSharePdf,
                      onConfirmDispatch: onConfirmDispatch,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final DespachoDocumentoData documento;
  const _Header({required this.documento});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_moodPurple, Color(0xFF7E57C2)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _moodPurple.withOpacity(0.20), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vista previa de despacho',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${documento.codigoPedido} · ${documento.items.length} productos · ${documento.totalUnidades} unidades',
                  style: TextStyle(color: Colors.white.withOpacity(0.88), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Text('C\$ ${documento.totalFinal.toStringAsFixed(2)}', style: const TextStyle(color: _moodPurple, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  final DespachoDocumentoData documento;
  const _ClienteCard({required this.documento});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Datos del cliente',
      icon: Icons.person_pin_circle_outlined,
      children: [
        _InfoLine(label: 'Cliente', value: documento.clienteVisible),
        _InfoLine(label: 'Teléfono', value: documento.telefonoVisible),
        _InfoLine(label: 'Correo', value: documento.correoVisible),
        _InfoLine(label: 'Dirección', value: documento.direccionVisible),
        if (documento.referenciaDireccion.isNotEmpty) _InfoLine(label: 'Referencia', value: documento.referenciaDireccion),
        _InfoLine(label: 'Zona', value: documento.zonaVisible),
        if (documento.municipio.isNotEmpty || documento.departamento.isNotEmpty)
          _InfoLine(label: 'Ubicación', value: '${documento.municipio} ${documento.departamento}'.trim()),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final DespachoDocumentoData documento;
  const _ResumenCard({required this.documento});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Resumen operativo',
      icon: Icons.fact_check_outlined,
      children: [
        _InfoLine(label: 'Estado pago', value: documento.estadoPago.isEmpty ? 'No disponible' : documento.estadoPago),
        _InfoLine(label: 'Estado pedido', value: documento.estadoNombre),
        _InfoLine(label: 'Referencia', value: documento.referenciaVisible),
        _InfoLine(label: 'Banco / moneda', value: '${documento.bancoTransferencia.isEmpty ? 'N/D' : documento.bancoTransferencia} / ${documento.monedaPago}'),
        _InfoLine(label: 'Subtotal', value: 'C\$ ${documento.subtotal.toStringAsFixed(2)}'),
        _InfoLine(label: 'Envío', value: 'C\$ ${documento.costoEnvio.toStringAsFixed(2)}'),
        _InfoLine(label: 'Total final', value: 'C\$ ${documento.totalFinal.toStringAsFixed(2)}', strong: true),
      ],
    );
  }
}

class _ProductosCard extends StatelessWidget {
  final DespachoDocumentoData documento;
  const _ProductosCard({required this.documento});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Productos a despachar',
      icon: Icons.inventory_2_outlined,
      children: documento.items.isEmpty
          ? [const Text('No hay productos en el detalle del pedido.')]
          : documento.items.map((item) => _ProductoRow(item: item)).toList(),
    );
  }
}

class _ProductoRow extends StatelessWidget {
  final DespachoDocumentoItem item;
  const _ProductoRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _moodBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('x${item.cantidad}', style: const TextStyle(color: _moodPurple, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _moodText, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  'Imagen: ${item.productoImagenId > 0 ? '#${item.productoImagenId}' : 'N/D'} · Precio: C\$ ${item.precioFinal.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text('C\$ ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: _moodText, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool loading;
  final bool puedeDespacharse;
  final VoidCallback onPreviewPdf;
  final VoidCallback onSharePdf;
  final VoidCallback onConfirmDispatch;

  const _ActionBar({
    required this.loading,
    required this.puedeDespacharse,
    required this.onPreviewPdf,
    required this.onSharePdf,
    required this.onConfirmDispatch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final buttons = [
          OutlinedButton.icon(
            onPressed: loading ? null : onPreviewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Ver PDF'),
          ),
          OutlinedButton.icon(
            onPressed: loading ? null : onSharePdf,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Guardar PDF'),
          ),
          FilledButton.icon(
            onPressed: loading || !puedeDespacharse ? null : onConfirmDispatch,
            icon: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.local_shipping_rounded),
            label: Text(loading ? 'Despachando...' : 'Despachar y generar PDF'),
          ),
        ];

        if (compact) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons.map((b) => Padding(padding: const EdgeInsets.only(bottom: 10), child: b)).toList());
        }
        return Row(children: buttons.map((b) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: b))).toList());
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Panel({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _moodPurple),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: _moodText))),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _InfoLine({required this.label, required this.value, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value.isEmpty ? 'No disponible' : value, style: TextStyle(color: _moodText, fontWeight: strong ? FontWeight.w900 : FontWeight.w600))),
        ],
      ),
    );
  }
}
