import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/admin/despacho_documento_model.dart';

class DespachoPdfService {
  const DespachoPdfService._();

  static String fileName(DespachoDocumentoData data) {
    final clean = data.codigoPedido.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return 'despacho_${clean.isEmpty ? data.pedidoId : clean}.pdf';
  }

  static Future<Uint8List> buildPdf(DespachoDocumentoData data) async {
    final doc = pw.Document(title: 'Despacho ${data.codigoPedido}', author: 'MOOD Professional Hair Experience');
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          _header(data, now),
          pw.SizedBox(height: 16),
          _sectionTitle('Datos del cliente'),
          _clientBlock(data),
          pw.SizedBox(height: 14),
          _sectionTitle('Productos a despachar'),
          _itemsTable(data),
          pw.SizedBox(height: 14),
          _totals(data),
          pw.SizedBox(height: 18),
          _controlBlock(data),
          pw.SizedBox(height: 24),
          _signatureBlock(),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('MOOD Professional Hair Experience', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('Pagina ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<void> previewPdf(DespachoDocumentoData data) async {
    final bytes = await buildPdf(data);
    await Printing.layoutPdf(name: fileName(data), onLayout: (_) async => bytes);
  }

  static Future<void> sharePdf(DespachoDocumentoData data) async {
    final bytes = await buildPdf(data);
    await Printing.sharePdf(bytes: bytes, filename: fileName(data));
  }

  static pw.Widget _header(DespachoDocumentoData data, DateTime now) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2C3E50'),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MOOD', style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.Text('Professional Hair Experience', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                pw.SizedBox(height: 12),
                pw.Text('Guia de despacho', style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Pedido: ${data.codigoPedido}', style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Fecha de generacion', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text(_formatDate(now), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 7),
                pw.Text('Estado', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text(data.estadoNombre, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2C3E50'))),
    );
  }

  static pw.Widget _clientBlock(DespachoDocumentoData data) {
    final direccionCompleta = [
      data.direccionVisible,
      if (data.referenciaDireccion.isNotEmpty) 'Referencia: ${data.referenciaDireccion}',
      if (data.municipio.isNotEmpty || data.departamento.isNotEmpty) '${data.municipio} ${data.departamento}'.trim(),
    ].where((x) => x.trim().isNotEmpty).join('\n');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(12)),
      child: pw.Column(
        children: [
          pw.Row(children: [
            _infoCell('Cliente', data.clienteVisible),
            _infoCell('Telefono', data.telefonoVisible),
            _infoCell('Correo', data.correoVisible),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _infoCell('Zona de envio', data.zonaVisible),
            _infoCell('Referencia de pago', data.referenciaVisible),
            _infoCell('Banco / moneda', '${data.bancoTransferencia.isEmpty ? 'N/D' : data.bancoTransferencia} / ${data.monedaPago}'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(child: _infoBox('Direccion de entrega', direccionCompleta)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _infoCell(String label, String value) => pw.Expanded(child: _infoBox(label, value));

  static pw.Widget _infoBox(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA'), borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(value.isEmpty ? 'No disponible' : value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(DespachoDocumentoData data) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#5E35B1')),
        children: [
          _tableHeader('Cant.'),
          _tableHeader('Producto'),
          _tableHeader('Imagen'),
          _tableHeader('Precio'),
          _tableHeader('Subtotal'),
        ],
      ),
      if (data.items.isEmpty)
        pw.TableRow(
          children: [
            _tableCell('-'),
            _tableCell('Sin productos en detalle'),
            _tableCell('-'),
            _tableCell('-'),
            _tableCell('-'),
          ],
        )
      else
        ...data.items.map((item) {
          return pw.TableRow(
            children: [
              _tableCell(item.cantidad.toString()),
              _tableCell(item.nombre),
              _tableCell(item.productoImagenId > 0 ? '#${item.productoImagenId}' : '-'),
              _tableCell('C\$ ${item.precioFinal.toStringAsFixed(2)}'),
              _tableCell('C\$ ${item.subtotal.toStringAsFixed(2)}'),
            ],
          );
        }),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(38),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(55),
        3: pw.FixedColumnWidth(70),
        4: pw.FixedColumnWidth(75),
      },
      children: rows,
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _totals(DespachoDocumentoData data) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 230,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F7FA'), borderRadius: pw.BorderRadius.circular(12)),
        child: pw.Column(
          children: [
            _totalRow('Subtotal', data.subtotal),
            _totalRow('Envio', data.costoEnvio),
            if (data.descuento > 0) _totalRow('Descuento', -data.descuento),
            if (data.impuesto > 0) _totalRow('Impuesto', data.impuesto),
            pw.Divider(color: PdfColors.grey500),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total final', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('C\$ ${data.totalFinal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text('C\$ ${value.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _controlBlock(DespachoDocumentoData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Control operativo', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Unidades a despachar: ${data.totalUnidades}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Productos en documento: ${data.items.length}', style: const pw.TextStyle(fontSize: 9)),
          if (data.observacion.isNotEmpty) pw.Text('Observacion: ${data.observacion}', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock() {
    return pw.Row(
      children: [
        _signature('Entrega bodega/despacho'),
        pw.SizedBox(width: 24),
        _signature('Recibe cliente / transporte'),
      ],
    );
  }

  static pw.Widget _signature(String label) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Container(height: 38),
          pw.Divider(color: PdfColors.grey700),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
