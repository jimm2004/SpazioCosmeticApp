import 'package:flutter/material.dart';

import '../../controllers/catalogo/perfil_controller.dart';
import '../../models/catalogo/datos_cliente_model.dart';
import 'mood_palette.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PerfilController controller = PerfilController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
    controller.cargar();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoodPalette.background,
      appBar: AppBar(
        backgroundColor: MoodPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoodPalette.text),
        title: const Text('Mi perfil', style: TextStyle(color: MoodPalette.text, fontWeight: FontWeight.w900)),
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: MoodPalette.pink))
          : RefreshIndicator(
              color: MoodPalette.pink,
              onRefresh: controller.cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                children: [
                  if (controller.error != null) ...[
                    _MessageCard(message: controller.error!, error: true),
                    const SizedBox(height: 12),
                  ],
                  _UserCard(
                    name: controller.usuario?.name ?? controller.datosCliente?.nombres ?? 'Cliente',
                    email: controller.usuario?.email ?? '',
                    role: controller.usuario?.role ?? 'cliente',
                  ),
                  const SizedBox(height: 14),
                  _DatosClienteForm(controller: controller),
                ],
              ),
            ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  const _UserCard({required this.name, required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: MoodPalette.mainGradient, borderRadius: BorderRadius.circular(26), boxShadow: [MoodPalette.cardShadow(.14)]),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.4))),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              if (email.isNotEmpty) Text(email, style: TextStyle(color: Colors.white.withOpacity(.82), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(role.replaceAll('_', ' '), style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DatosClienteForm extends StatefulWidget {
  final PerfilController controller;
  const _DatosClienteForm({required this.controller});

  @override
  State<_DatosClienteForm> createState() => _DatosClienteFormState();
}

class _DatosClienteFormState extends State<_DatosClienteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nombres;
  late TextEditingController apellidos;
  late TextEditingController telefono;
  late TextEditingController direccion;
  late TextEditingController referencia;
  int? zonaId;
  int? departamentoId;
  int? municipioId;
  bool loadingDeps = false;
  bool loadingMuns = false;

  @override
  void initState() {
    super.initState();
    final d = widget.controller.datosCliente;
    nombres = TextEditingController(text: d?.nombres.isNotEmpty == true ? d!.nombres : widget.controller.usuario?.name ?? '');
    apellidos = TextEditingController(text: d?.apellidos ?? '');
    telefono = TextEditingController(text: d?.telefono ?? '');
    direccion = TextEditingController(text: d?.direccion ?? '');
    referencia = TextEditingController(text: d?.referencia ?? '');
    zonaId = d?.zonaId;
    departamentoId = d?.departamentoId;
    municipioId = d?.municipioId;
  }

  @override
  void didUpdateWidget(covariant _DatosClienteForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final d = widget.controller.datosCliente;
    if (oldWidget.controller.loading && !widget.controller.loading) {
      nombres.text = d?.nombres.isNotEmpty == true ? d!.nombres : widget.controller.usuario?.name ?? '';
      apellidos.text = d?.apellidos ?? '';
      telefono.text = d?.telefono ?? '';
      direccion.text = d?.direccion ?? '';
      referencia.text = d?.referencia ?? '';
      zonaId = d?.zonaId;
      departamentoId = d?.departamentoId;
      municipioId = d?.municipioId;
    }
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

  Future<void> _onZonaChanged(int? value) async {
    setState(() {
      zonaId = value;
      departamentoId = null;
      municipioId = null;
      loadingDeps = true;
    });
    await widget.controller.seleccionarZona(value);
    if (mounted) setState(() => loadingDeps = false);
  }

  Future<void> _onDepartamentoChanged(int? value) async {
    setState(() {
      departamentoId = value;
      municipioId = null;
      loadingMuns = true;
    });
    await widget.controller.seleccionarDepartamento(value);
    if (mounted) setState(() => loadingMuns = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await widget.controller.guardar(
      DatosClienteModel(
        id: widget.controller.datosCliente?.id,
        nombres: nombres.text.trim(),
        apellidos: apellidos.text.trim(),
        telefono: telefono.text.trim(),
        direccion: direccion.text.trim(),
        referencia: referencia.text.trim(),
        zonaId: zonaId,
        departamentoId: departamentoId,
        municipioId: municipioId,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Perfil actualizado' : widget.controller.error ?? 'No se pudo guardar'), backgroundColor: ok ? Colors.green : Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonas = widget.controller.zonas;
    final departamentos = widget.controller.departamentos;
    final municipios = widget.controller.municipios;
    final safeZona = zonas.any((z) => z.id == zonaId) ? zonaId : null;
    final safeDepartamento = departamentos.any((d) => d.id == departamentoId) ? departamentoId : null;
    final safeMunicipio = municipios.any((m) => m.id == municipioId) ? municipioId : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [MoodPalette.cardShadow(.06)]),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Datos de entrega', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
          const SizedBox(height: 12),
          _field(nombres, 'Nombres', Icons.person_outline, required: true),
          _field(apellidos, 'Apellidos', Icons.badge_outlined),
          _field(telefono, 'Teléfono', Icons.phone_outlined, required: true, keyboard: TextInputType.phone),
          DropdownButtonFormField<int>(
            value: safeZona,
            decoration: _decoration('Zona', Icons.map_outlined),
            items: zonas.map((z) => DropdownMenuItem<int>(value: z.id, child: Text(z.nombreZona))).toList(),
            onChanged: widget.controller.saving ? null : _onZonaChanged,
            validator: (value) => value == null ? 'Seleccioná zona' : null,
          ),
          const SizedBox(height: 10),
          if (loadingDeps) const LinearProgressIndicator(color: MoodPalette.pink),
          DropdownButtonFormField<int>(
            value: safeDepartamento,
            decoration: _decoration('Departamento', Icons.location_city_outlined),
            items: departamentos.map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.nombre))).toList(),
            onChanged: widget.controller.saving || loadingDeps ? null : _onDepartamentoChanged,
            validator: (value) => value == null ? 'Seleccioná departamento' : null,
          ),
          const SizedBox(height: 10),
          if (loadingMuns) const LinearProgressIndicator(color: MoodPalette.pink),
          DropdownButtonFormField<int>(
            value: safeMunicipio,
            decoration: _decoration('Municipio', Icons.place_outlined),
            items: municipios.map((m) => DropdownMenuItem<int>(value: m.id, child: Text(m.nombre))).toList(),
            onChanged: widget.controller.saving || loadingMuns ? null : (value) => setState(() => municipioId = value),
            validator: (value) => value == null ? 'Seleccioná municipio' : null,
          ),
          const SizedBox(height: 10),
          _field(direccion, 'Dirección exacta', Icons.home_outlined, required: true),
          _field(referencia, 'Referencia de ubicación', Icons.notes_outlined, required: true),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.controller.saving ? null : _guardar,
              icon: widget.controller.saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(widget.controller.saving ? 'Guardando...' : 'Guardar perfil'),
              style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool required = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: required ? (v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null : null,
        decoration: _decoration(label, icon),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: MoodPalette.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool error;
  const _MessageCard({required this.message, this.error = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: error ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(18)),
        child: Text(message, style: TextStyle(color: error ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.w700)),
      );
}
