import 'package:flutter/material.dart';

import '../../../../models/admin/despacho_documento_model.dart';

const _moodBlack = Color(0xFF111111);
const _moodText = Color(0xFF1F1F1F);
const _moodMuted = Color(0xFF666666);
const _moodBg = Color(0xFFF7F7F7);
const _moodBorder = Color(0xFFE0E0E0);
const _moodWhite = Color(0xFFFFFFFF);

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
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 34 : 18,
                    18,
                    isWide ? 34 : 18,
                    26,
                  ),
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
                    _FooterDocumento(documento: documento),
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
        color: _moodWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _moodBlack, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 78,
                height: 58,
                decoration: BoxDecoration(
                  color: _moodWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _moodBlack, width: 1.2),
                ),
                child: const Center(
                  child: Text(
                    'MOOD',
                    style: TextStyle(
                      color: _moodBlack,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Mood',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _moodBlack,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Sistema de Control de Pedidos y Despacho',
                      style: TextStyle(
                        color: _moodText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Generado por Store Mood',
                      style: TextStyle(
                        color: _moodMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _moodBlack,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'C\$ ${documento.totalFinal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _moodWhite,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _moodBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _moodBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: _moodBlack,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vista previa de despacho',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _moodBlack,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '${documento.codigoPedido} · ${documento.items.length} productos · ${documento.totalUnidades} unidades',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _moodMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
        if (documento.referenciaDireccion.isNotEmpty)
          _InfoLine(
            label: 'Referencia',
            value: documento.referenciaDireccion,
          ),
        _InfoLine(label: 'Zona', value: documento.zonaVisible),
        if (documento.municipio.isNotEmpty ||
            documento.departamento.isNotEmpty)
          _InfoLine(
            label: 'Ubicación',
            value: '${documento.municipio} ${documento.departamento}'.trim(),
          ),
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
        _InfoLine(
          label: 'Estado pago',
          value: documento.estadoPago.isEmpty
              ? 'No disponible'
              : documento.estadoPago,
        ),
        _InfoLine(label: 'Estado pedido', value: documento.estadoNombre),
        _InfoLine(label: 'Referencia', value: documento.referenciaVisible),
        _InfoLine(
          label: 'Banco / moneda',
          value:
              '${documento.bancoTransferencia.isEmpty ? 'N/D' : documento.bancoTransferencia} / ${documento.monedaPago}',
        ),
        _InfoLine(
          label: 'Subtotal',
          value: 'C\$ ${documento.subtotal.toStringAsFixed(2)}',
        ),
        _InfoLine(
          label: 'Envío',
          value: 'C\$ ${documento.costoEnvio.toStringAsFixed(2)}',
        ),
        _InfoLine(
          label: 'Total final',
          value: 'C\$ ${documento.totalFinal.toStringAsFixed(2)}',
          strong: true,
        ),
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
          ? [
              const Text(
                'No hay productos en el detalle del pedido.',
                style: TextStyle(
                  color: _moodMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]
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
      decoration: BoxDecoration(
        color: _moodWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _moodBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _moodBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _moodBlack, width: 1),
            ),
            child: Center(
              child: Text(
                'x${item.cantidad}',
                style: const TextStyle(
                  color: _moodBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _moodText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Imagen: ${item.productoImagenId > 0 ? '#${item.productoImagenId}' : 'N/D'} · Precio: \$ ${item.precioFinal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _moodMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$ ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _moodText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterDocumento extends StatelessWidget {
  final DespachoDocumentoData documento;

  const _FooterDocumento({required this.documento});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _moodWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _moodBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: _moodBlack,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Documento generado por Store Mood para ${documento.codigoPedido}.',
              style: const TextStyle(
                color: _moodText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: _moodBlack,
      side: const BorderSide(color: _moodBlack, width: 1.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

    final filledStyle = FilledButton.styleFrom(
      backgroundColor: _moodBlack,
      foregroundColor: _moodWhite,
      disabledBackgroundColor: Colors.grey.shade400,
      disabledForegroundColor: _moodWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;

        final buttons = [
          OutlinedButton.icon(
            style: outlinedStyle,
            onPressed: loading ? null : onPreviewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text(
              'Ver PDF',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton.icon(
            style: outlinedStyle,
            onPressed: loading ? null : onSharePdf,
            icon: const Icon(Icons.download_outlined),
            label: const Text(
              'Guardar PDF',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton.icon(
            style: filledStyle,
            onPressed: loading || !puedeDespacharse ? null : onConfirmDispatch,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _moodWhite,
                    ),
                  )
                : const Icon(Icons.local_shipping_outlined),
            label: Text(
              loading ? 'Despachando...' : 'Despachar y generar PDF',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ];

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: b,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: buttons
              .map(
                (b) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: b,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Panel({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _moodWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _moodBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _moodBlack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _moodText,
                      ),
                ),
              ),
            ],
          ),
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

  const _InfoLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'No disponible' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: _moodMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cleanValue,
              style: TextStyle(
                color: _moodText,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}