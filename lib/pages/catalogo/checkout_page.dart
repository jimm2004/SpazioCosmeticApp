import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/cart_controller.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final cart = CartController.instance;

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  String metodoPago = 'Efectivo';

  Future<void> _enviarPedido() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _telefonoCtrl.text.trim().isEmpty ||
        _direccionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre, teléfono y dirección')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Hola, quiero realizar este pedido:');
    buffer.writeln('');
    buffer.writeln('Cliente: ${_nombreCtrl.text.trim()}');
    buffer.writeln('Teléfono: ${_telefonoCtrl.text.trim()}');
    buffer.writeln('Dirección: ${_direccionCtrl.text.trim()}');
    buffer.writeln('Referencia: ${_referenciaCtrl.text.trim()}');
    buffer.writeln('Método de pago: $metodoPago');
    buffer.writeln('Observaciones: ${_observacionesCtrl.text.trim()}');
    buffer.writeln('');
    buffer.writeln('Detalle del pedido:');

    for (final item in cart.items) {
      buffer.writeln(
        '- ${item.nombre} x${item.cantidad} = \$${item.subtotal.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('Total: \$${cart.total.toStringAsFixed(2)}');

    final url = Uri.parse(
      'https://wa.me/50578496665?text=${Uri.encodeComponent(buffer.toString())}',
    );

    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (ok) {
      cart.limpiar();
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _referenciaCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.withAlpha(60)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar pedido')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nombreCtrl,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              border: style,
              enabledBorder: style,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              border: style,
              enabledBorder: style,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _direccionCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Dirección',
              border: style,
              enabledBorder: style,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _referenciaCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Referencia de entrega',
              hintText: 'Ej: casa azul, portón negro, del parque 2 cuadras abajo',
              border: style,
              enabledBorder: style,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: metodoPago,
            decoration: InputDecoration(
              labelText: 'Método de pago',
              border: style,
              enabledBorder: style,
            ),
            items: const [
              DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
              DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
              DropdownMenuItem(value: 'Pago contra entrega', child: Text('Pago contra entrega')),
            ],
            onChanged: (value) {
              setState(() {
                metodoPago = value!;
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _observacionesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observaciones',
              border: style,
              enabledBorder: style,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del pedido',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${item.nombre} x${item.cantidad} - \$${item.subtotal.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${cart.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enviarPedido,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Confirmar pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}