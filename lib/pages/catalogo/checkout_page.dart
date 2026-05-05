import 'package:flutter/material.dart';

import '../../controllers/catalogo/cart_controller.dart';
import '../../controllers/catalogo/checkout_controller.dart';
import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/metodo_pago_model.dart';
import 'mood_palette.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CheckoutController controller = CheckoutController();
  final TextEditingController referenciaCtrl = TextEditingController();
  final TextEditingController observacionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
    controller.inicializar();
  }

  @override
  void dispose() {
    controller.removeListener(_sync);
    controller.dispose();
    referenciaCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmar() async {
    if (controller.requiereDatosCliente) {
      await _showDatosClienteModal(forzar: true);
      if (!mounted) return;
      if (controller.requiereDatosCliente) return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Confirmar pedido', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Tu pedido quedará en revisión de transferencia. Total: \$ ${controller.total.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmar != true) return;

    final result = await controller.confirmarPedido(
      referenciaTransferencia: referenciaCtrl.text,
      observacion: observacionCtrl.text,
    );

    if (!mounted) return;

    if (result != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Pedido enviado', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('Tu pedido fue registrado. El pago queda pendiente de revisión contable.'),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Listo'))],
        ),
      );
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.error ?? 'No se pudo confirmar'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _showDatosClienteModal({bool forzar = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: !forzar,
      enableDrag: !forzar,
      builder: (_) => _DatosClienteRequiredSheet(controller: controller, forzar: forzar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    return Scaffold(
      backgroundColor: MoodPalette.background,
      appBar: AppBar(
        backgroundColor: MoodPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoodPalette.text),
        title: const Text('Pedido y pago', style: TextStyle(color: MoodPalette.text, fontWeight: FontWeight.w900)),
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: MoodPalette.pink))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 140),
              children: [
                _SummaryCard(
                  subtotal: cart.subtotal,
                  costoEnvio: controller.costoEnvio,
                  total: controller.total,
                  zona: controller.zonaEnvio,
                  porcentaje: controller.porcentajeEnvio,
                ),
                const SizedBox(height: 14),
                _CustomerStatusCard(
                  completo: !controller.requiereDatosCliente,
                  datos: controller.datosCliente,
                  onTap: () => _showDatosClienteModal(),
                ),
                const SizedBox(height: 14),
                _PaymentMethods(
                  metodos: controller.metodosPago,
                  seleccionado: controller.metodoSeleccionado,
                  onSelect: controller.seleccionarMetodo,
                ),
                const SizedBox(height: 14),
                _InputCard(
                  child: TextField(
                    controller: referenciaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Referencia de transferencia',
                      hintText: 'Ej: 9845321 / comprobante / número de operación',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.receipt_long_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _InputCard(
                  child: TextField(
                    controller: observacionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observación opcional',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: controller.loading
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(26)), boxShadow: [MoodPalette.cardShadow(.12)]),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [const Text('Total final', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('\$ ${controller.total.toStringAsFixed(2)}', style: const TextStyle(color: MoodPalette.pink, fontWeight: FontWeight.w900, fontSize: 22))]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.saving ? null : _confirmar,
                        icon: controller.saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.verified_rounded),
                        label: Text(controller.saving ? 'Registrando...' : 'Confirmar pedido'),
                        style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double costoEnvio;
  final double total;
  final String zona;
  final double porcentaje;
  const _SummaryCard({required this.subtotal, required this.costoEnvio, required this.total, required this.zona, required this.porcentaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: MoodPalette.mainGradient, borderRadius: BorderRadius.circular(26), boxShadow: [MoodPalette.cardShadow(.16)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 14),
          _row('Subtotal', '\$ ${subtotal.toStringAsFixed(2)}'),
          _row('Envío ${zona.isEmpty ? '' : '($zona)'}', '\$ ${costoEnvio.toStringAsFixed(2)}'),
          if (porcentaje > 0) _row('Porcentaje envío', '${porcentaje.toStringAsFixed(2)}%'),
          const Divider(color: Colors.white30),
          _row('Total', '\$ ${total.toStringAsFixed(2)}', big: true),
        ],
      ),
    );
  }

  Widget _row(String a, String b, {bool big = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Text(a, style: TextStyle(color: Colors.white.withOpacity(.82), fontWeight: FontWeight.w700)), const Spacer(), Text(b, style: TextStyle(color: Colors.white, fontSize: big ? 21 : 15, fontWeight: FontWeight.w900))]),
      );
}

class _CustomerStatusCard extends StatelessWidget {
  final bool completo;
  final DatosClienteModel? datos;
  final VoidCallback onTap;
  const _CustomerStatusCard({required this.completo, this.datos, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.06)]),
        child: Row(
          children: [
            Icon(completo ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: completo ? Colors.green : Colors.orange),
            const SizedBox(width: 12),
            Expanded(child: Text(completo ? '${datos?.nombres ?? ''} · ${datos?.telefono ?? ''}' : 'Debés completar tus datos de entrega antes de pedir', style: const TextStyle(fontWeight: FontWeight.w800))),
            const Icon(Icons.edit_rounded, color: MoodPalette.pink),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  final List<MetodoPagoModel> metodos;
  final MetodoPagoModel? seleccionado;
  final ValueChanged<MetodoPagoModel> onSelect;

  const _PaymentMethods({
    required this.metodos,
    required this.seleccionado,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.06)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Continuar con tipo de pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Transferencia bancaria', style: TextStyle(color: MoodPalette.muted)),
          const SizedBox(height: 12),
          if (metodos.isEmpty)
            const Text('No hay métodos de pago activos.')
          else
            ...metodos.map((m) {
              final selected = seleccionado?.id == m.id;
              return GestureDetector(
                onTap: () => onSelect(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: selected ? MoodPalette.softPink : const Color(0xFFF8F8FA), borderRadius: BorderRadius.circular(17), border: Border.all(color: selected ? MoodPalette.pink : Colors.grey.shade200, width: selected ? 2 : 1)),
                  child: Row(
                    children: [
                      Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: MoodPalette.pink),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.nombreVisible, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text('Cuenta: ${m.numeroCuenta}', style: const TextStyle(fontSize: 12)),
                          Text('Titular: ${m.titular}', style: const TextStyle(fontSize: 12, color: MoodPalette.muted)),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DatosClienteRequiredSheet extends StatefulWidget {
  final CheckoutController controller;
  final bool forzar;
  const _DatosClienteRequiredSheet({required this.controller, required this.forzar});

  @override
  State<_DatosClienteRequiredSheet> createState() => _DatosClienteRequiredSheetState();
}

class _DatosClienteRequiredSheetState extends State<_DatosClienteRequiredSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nombres;
  late final TextEditingController apellidos;
  late final TextEditingController telefono;
  late final TextEditingController direccion;
  late final TextEditingController referencia;
  int? departamentoId;

  @override
  void initState() {
    super.initState();
    final d = widget.controller.datosCliente;
    nombres = TextEditingController(text: d?.nombres ?? '');
    apellidos = TextEditingController(text: d?.apellidos ?? '');
    telefono = TextEditingController(text: d?.telefono ?? '');
    direccion = TextEditingController(text: d?.direccion ?? '');
    referencia = TextEditingController(text: d?.referencia ?? '');
    departamentoId = d?.departamentoId;
  }

  @override
  void dispose() {
    nombres.dispose();
    apellidos.dispose();
    telefono.dispose();
    direccion.dispose();
    referencia.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.controller.guardarDatos(DatosClienteModel(nombres: nombres.text.trim(), apellidos: apellidos.text.trim(), telefono: telefono.text.trim(), direccion: direccion.text.trim(), referencia: referencia.text.trim(), departamentoId: departamentoId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Datos guardados' : widget.controller.error ?? 'Error'), backgroundColor: ok ? Colors.green : Colors.redAccent));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: MoodPalette.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: Text(widget.forzar ? 'Datos obligatorios para el pedido' : 'Datos de entrega', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))), if (!widget.forzar) IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))]),
              const SizedBox(height: 12),
              _field(nombres, 'Nombres', Icons.person_outline, true),
              _field(apellidos, 'Apellidos', Icons.badge_outlined, false),
              _field(telefono, 'Teléfono', Icons.phone_outlined, true, keyboard: TextInputType.phone),
              DropdownButtonFormField<int>(
                value: departamentoId,
                decoration: _decoration('Departamento / zona', Icons.location_city_outlined),
                items: widget.controller.departamentos.map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.nombre))).toList(),
                onChanged: (value) => setState(() => departamentoId = value),
                validator: (value) => value == null ? 'Seleccioná departamento' : null,
              ),
              const SizedBox(height: 10),
              _field(direccion, 'Dirección', Icons.home_outlined, true),
              _field(referencia, 'Referencia', Icons.notes_outlined, false),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: widget.controller.saving ? null : _save, icon: const Icon(Icons.save_rounded), label: const Text('Guardar y continuar'), style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, bool required, {TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(controller: c, keyboardType: keyboard, validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null : null, decoration: _decoration(label, icon)),
      );
  InputDecoration _decoration(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));
}

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [MoodPalette.cardShadow(.05)]), child: child);
}
