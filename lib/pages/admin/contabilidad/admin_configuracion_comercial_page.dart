import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_configuracion_comercial_controller.dart';
import '../../../models/catalogo/metodo_pago_model.dart';
import '../../../models/catalogo/tarifa_envio_model.dart';
import '../../catalogo/mood_palette.dart';

class AdminConfiguracionComercialPage extends StatefulWidget {
  const AdminConfiguracionComercialPage({super.key});

  @override
  State<AdminConfiguracionComercialPage> createState() => _AdminConfiguracionComercialPageState();
}

class _AdminConfiguracionComercialPageState extends State<AdminConfiguracionComercialPage> {
  final AdminConfiguracionComercialController controller = AdminConfiguracionComercialController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
    controller.cargarTodo();
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

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? Colors.redAccent : Colors.green, behavior: SnackBarBehavior.floating));
  }

  Future<bool> _confirm(String title, String msg, String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: Text(msg),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white), child: Text(action)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _formMetodo({MetodoPagoModel? metodo}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MetodoPagoForm(
        metodo: metodo,
        onSave: ({required banco, required moneda, required titular, required numeroCuenta, required descripcion, required orden, required activo}) async {
          return controller.guardarMetodo(id: metodo?.id, banco: banco, moneda: moneda, titular: titular, numeroCuenta: numeroCuenta, descripcion: descripcion, orden: orden, activo: activo);
        },
      ),
    );
    if (ok == true) _snack(metodo == null ? 'Método creado' : 'Método actualizado');
    if (ok != true && controller.error != null) _snack(controller.error!, error: true);
  }

  Future<void> _toggleMetodo(MetodoPagoModel metodo, bool value) async {
    final okConfirm = await _confirm(value ? 'Activar método' : 'Desactivar método', '¿Confirmás el cambio de estado para ${metodo.nombreVisible}?', value ? 'Activar' : 'Desactivar');
    if (!okConfirm) return;
    final ok = await controller.cambiarEstadoMetodo(metodo, value);
    _snack(ok ? 'Estado actualizado' : controller.error ?? 'No se pudo actualizar', error: !ok);
  }

  Future<void> _editarTarifa(TarifaEnvioModel tarifa) async {
    final porcentajeCtrl = TextEditingController(text: tarifa.porcentajeEnvio.toStringAsFixed(2));
    final descripcionCtrl = TextEditingController(text: tarifa.descripcion);
    bool activo = tarifa.activo;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Container(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: MoodPalette.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [Expanded(child: Text('Editar ${tarifa.nombreZona}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded))]),
              TextField(controller: porcentajeCtrl, keyboardType: TextInputType.number, decoration: _input('Porcentaje de envío', Icons.percent_rounded)),
              const SizedBox(height: 10),
              TextField(controller: descripcionCtrl, decoration: _input('Descripción', Icons.notes_rounded)),
              SwitchListTile(value: activo, onChanged: (v) => setModal(() => activo = v), title: const Text('Activo', style: TextStyle(fontWeight: FontWeight.w800)), activeColor: MoodPalette.pink),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(context, true), icon: const Icon(Icons.save_rounded), label: const Text('Guardar tarifa'), style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;
    final porcentaje = double.tryParse(porcentajeCtrl.text.replaceAll(',', '.')) ?? tarifa.porcentajeEnvio;
    final saved = await controller.actualizarTarifa(tarifa, porcentaje, activo, descripcionCtrl.text.trim());
    _snack(saved ? 'Tarifa actualizada' : controller.error ?? 'No se pudo actualizar', error: !saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoodPalette.background,
      appBar: AppBar(
        backgroundColor: MoodPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoodPalette.text),
        title: const Text('Administración contable', style: TextStyle(color: MoodPalette.text, fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: controller.loading ? null : controller.cargarTodo, icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formMetodo(),
        backgroundColor: MoodPalette.pink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Agregar cuenta'),
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: MoodPalette.pink))
          : RefreshIndicator(
              onRefresh: controller.cargarTodo,
              color: MoodPalette.pink,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  const _Hero(),
                  const SizedBox(height: 18),
                  const Text('Cuentas de transferencia', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ...controller.metodos.map((m) => _MetodoCard(metodo: m, onEdit: () => _formMetodo(metodo: m), onToggle: (v) => _toggleMetodo(m, v))),
                  const SizedBox(height: 22),
                  const Text('Tarifas de envío por zona', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  ...controller.tarifas.map((t) => _TarifaCard(tarifa: t, onEdit: () => _editarTarifa(t))),
                ],
              ),
            ),
    );
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: MoodPalette.mainGradient, borderRadius: BorderRadius.circular(28), boxShadow: [MoodPalette.cardShadow(.16)]),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.account_balance_rounded, color: Colors.white, size: 36),
          SizedBox(height: 12),
          Text('Pagos y envíos', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          SizedBox(height: 6),
          Text('Administra cuentas bancarias y porcentajes de envío por zona.', style: TextStyle(color: Colors.white70, height: 1.4)),
        ]),
      );
}

class _MetodoCard extends StatelessWidget {
  final MetodoPagoModel metodo;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  const _MetodoCard({required this.metodo, required this.onEdit, required this.onToggle});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.06)]),
        child: Row(children: [
          CircleAvatar(backgroundColor: metodo.activo ? MoodPalette.softPink : Colors.grey.shade200, child: Icon(Icons.account_balance_rounded, color: metodo.activo ? MoodPalette.pink : Colors.grey)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(metodo.nombreVisible, style: const TextStyle(fontWeight: FontWeight.w900)), Text('Cuenta: ${metodo.numeroCuenta}'), Text('Titular: ${metodo.titular}', style: const TextStyle(color: MoodPalette.muted))])),
          Switch(value: metodo.activo, activeColor: MoodPalette.pink, onChanged: onToggle),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: MoodPalette.purple)),
        ]),
      );
}

class _TarifaCard extends StatelessWidget {
  final TarifaEnvioModel tarifa;
  final VoidCallback onEdit;
  const _TarifaCard({required this.tarifa, required this.onEdit});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.06)]),
        child: Row(children: [
          CircleAvatar(backgroundColor: MoodPalette.softPurple, child: Text('${tarifa.porcentajeEnvio.toStringAsFixed(0)}%', style: const TextStyle(color: MoodPalette.deepPurple, fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tarifa.nombreZona, style: const TextStyle(fontWeight: FontWeight.w900)), Text(tarifa.descripcion.isEmpty ? 'Tarifa de envío activa' : tarifa.descripcion, style: const TextStyle(color: MoodPalette.muted))])),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: MoodPalette.pink)),
        ]),
      );
}

typedef MetodoSave = Future<bool> Function({
  required String banco,
  required String moneda,
  required String titular,
  required String numeroCuenta,
  required String descripcion,
  required int orden,
  required bool activo,
});

class _MetodoPagoForm extends StatefulWidget {
  final MetodoPagoModel? metodo;
  final MetodoSave onSave;
  const _MetodoPagoForm({this.metodo, required this.onSave});
  @override
  State<_MetodoPagoForm> createState() => _MetodoPagoFormState();
}

class _MetodoPagoFormState extends State<_MetodoPagoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titular;
  late final TextEditingController cuenta;
  late final TextEditingController descripcion;
  late final TextEditingController orden;
  String banco = 'BAC';
  String moneda = r'$';
  bool activo = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.metodo;
    banco = m?.banco ?? 'BAC';
    moneda = m?.moneda ?? r'$';
    activo = m?.activo ?? true;
    titular = TextEditingController(text: m?.titular ?? '');
    cuenta = TextEditingController(text: m?.numeroCuenta ?? '');
    descripcion = TextEditingController(text: m?.descripcion ?? '');
    orden = TextEditingController(text: (m?.orden ?? 1).toString());
  }

  @override
  void dispose() {
    titular.dispose();
    cuenta.dispose();
    descripcion.dispose();
    orden.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await widget.onSave(banco: banco, moneda: moneda, titular: titular.text.trim(), numeroCuenta: cuenta.text.trim(), descripcion: descripcion.text.trim(), orden: int.tryParse(orden.text.trim()) ?? 1, activo: activo);
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: MoodPalette.background, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [Expanded(child: Text(widget.metodo == null ? 'Agregar cuenta' : 'Editar cuenta', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded))]),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: banco, decoration: _dec('Banco', Icons.account_balance_rounded), items: const ['BAC', 'Lafise', 'Banpro'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => banco = v ?? banco))),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<String>(value: moneda, decoration: _dec('Moneda', Icons.payments_rounded), items: const [r'$'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => moneda = v ?? moneda))),
            ]),
            const SizedBox(height: 10),
            _field(titular, 'A nombre de', Icons.person_rounded),
            _field(cuenta, 'Número de cuenta', Icons.numbers_rounded),
            _field(descripcion, 'Descripción', Icons.notes_rounded, required: false),
            _field(orden, 'Orden', Icons.sort_rounded, keyboard: TextInputType.number),
            SwitchListTile(value: activo, activeColor: MoodPalette.pink, onChanged: (v) => setState(() => activo = v), title: const Text('Activo', style: TextStyle(fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: saving ? null : _save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded), label: Text(saving ? 'Guardando...' : 'Guardar cuenta'), style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool required = true, TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(top: 10), child: TextFormField(controller: c, keyboardType: keyboard, validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null : null, decoration: _dec(label, icon)));
  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));
}
