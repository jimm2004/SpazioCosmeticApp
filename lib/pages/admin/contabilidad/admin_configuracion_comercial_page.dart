import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_configuracion_comercial_controller.dart';
import '../../../models/catalogo/metodo_pago_model.dart';
import '../../../models/catalogo/tarifa_envio_model.dart';
import '../../catalogo/mood_palette.dart';

class AdminConfiguracionComercialPage extends StatefulWidget {
  const AdminConfiguracionComercialPage({super.key});

  @override
  State<AdminConfiguracionComercialPage> createState() =>
      _AdminConfiguracionComercialPageState();
}

class _AdminConfiguracionComercialPageState
    extends State<AdminConfiguracionComercialPage> {
  final AdminConfiguracionComercialController controller =
      AdminConfiguracionComercialController();

  final TextEditingController searchCtrl = TextEditingController();

  String filtro = '';
  String tab = 'metodos';

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
    searchCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  List<MetodoPagoModel> get metodosFiltrados {
    final q = filtro.trim().toLowerCase();

    if (q.isEmpty) return controller.metodos;

    return controller.metodos.where((m) {
      return m.nombreVisible.toLowerCase().contains(q) ||
          m.banco.toLowerCase().contains(q) ||
          m.moneda.toLowerCase().contains(q) ||
          m.titular.toLowerCase().contains(q) ||
          m.numeroCuenta.toLowerCase().contains(q) ||
          m.descripcion.toLowerCase().contains(q);
    }).toList();
  }

  List<TarifaEnvioModel> get tarifasFiltradas {
    final q = filtro.trim().toLowerCase();

    if (q.isEmpty) return controller.tarifas;

    return controller.tarifas.where((t) {
      return t.nombreZona.toLowerCase().contains(q) ||
          t.descripcion.toLowerCase().contains(q) ||
          t.porcentajeEnvio.toString().contains(q);
    }).toList();
  }

  Future<void> _refresh({bool message = false}) async {
    await controller.cargarTodo();

    if (message && mounted) {
      _snack('Configuración actualizada correctamente.',
          icon: Icons.refresh_rounded);
    }
  }

  void _snack(
    String msg, {
    bool error = false,
    IconData? icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(
              icon ?? (error ? Icons.error_outline_rounded : Icons.check),
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String msg,
    required String action,
    required IconData icon,
    required Color color,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(25),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: Text(
              msg,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(icon),
                label: Text(action),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
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
        onSave: ({
          required banco,
          required moneda,
          required titular,
          required numeroCuenta,
          required descripcion,
          required orden,
          required activo,
        }) async {
          return controller.guardarMetodo(
            id: metodo?.id,
            banco: banco,
            moneda: moneda,
            titular: titular,
            numeroCuenta: numeroCuenta,
            descripcion: descripcion,
            orden: orden,
            activo: activo,
          );
        },
      ),
    );

    if (ok == true) {
      _snack(
        metodo == null
            ? 'Método de pago creado correctamente.'
            : 'Método de pago actualizado correctamente.',
        icon: metodo == null ? Icons.add_card_rounded : Icons.edit_rounded,
      );
    } else if (ok == false && controller.error != null) {
      _snack(controller.error!, error: true);
    }
  }

  Future<void> _toggleMetodo(MetodoPagoModel metodo, bool value) async {
    final okConfirm = await _confirm(
      title: value ? 'Activar método' : 'Desactivar método',
      msg: value
          ? '¿Confirmás activar ${metodo.nombreVisible}?\n\nEl cliente podrá usarlo en checkout.'
          : '¿Confirmás desactivar ${metodo.nombreVisible}?\n\nEl cliente ya no verá esta cuenta al pagar.',
      action: value ? 'Activar' : 'Desactivar',
      icon: value ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
      color: value ? Colors.green : Colors.redAccent,
    );

    if (!okConfirm) return;

    final ok = await controller.cambiarEstadoMetodo(metodo, value);

    _snack(
      ok
          ? value
              ? 'Método activado correctamente.'
              : 'Método desactivado correctamente.'
          : controller.error ?? 'No se pudo actualizar.',
      error: !ok || !value,
      icon: value ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
    );
  }

  Future<void> _editarTarifa(TarifaEnvioModel tarifa) async {
    final porcentajeCtrl = TextEditingController(
      text: tarifa.porcentajeEnvio.toStringAsFixed(2),
    );
    final descripcionCtrl = TextEditingController(text: tarifa.descripcion);
    bool activo = tarifa.activo;
    bool saving = false;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          Future<void> guardar() async {
            final porcentaje = double.tryParse(
                  porcentajeCtrl.text.trim().replaceAll(',', '.'),
                ) ??
                tarifa.porcentajeEnvio;

            final confirmar = await _confirm(
              title: 'Guardar tarifa',
              msg:
                  '¿Confirmás actualizar esta tarifa?\n\nZona: ${tarifa.nombreZona}\nPorcentaje: ${porcentaje.toStringAsFixed(2)}%\nEstado: ${activo ? 'Activa' : 'Inactiva'}',
              action: 'Guardar',
              icon: Icons.save_rounded,
              color: MoodPalette.pink,
            );

            if (!confirmar) return;

            setModal(() => saving = true);

            final saved = await controller.actualizarTarifa(
              tarifa,
              porcentaje,
              activo,
              descripcionCtrl.text.trim(),
            );

            if (!context.mounted) return;

            setModal(() => saving = false);

            if (saved) {
              Navigator.pop(context, true);
            } else {
              Navigator.pop(context, false);
            }
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              18,
              18,
              18,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: MoodPalette.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: MoodPalette.pink.withAlpha(25),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: MoodPalette.pink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Editar ${tarifa.nombreZona}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        enabled: !saving,
                        controller: porcentajeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _input(
                          'Porcentaje de envío',
                          Icons.percent_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        enabled: !saving,
                        controller: descripcionCtrl,
                        maxLines: 2,
                        decoration: _input(
                          'Descripción',
                          Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: activo,
                        onChanged: saving
                            ? null
                            : (v) => setModal(() => activo = v),
                        title: const Text(
                          'Activo',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Si está apagado, esta tarifa no se usará para calcular envíos.',
                        ),
                        activeColor: MoodPalette.pink,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : guardar,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            saving ? 'Guardando...' : 'Guardar tarifa',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MoodPalette.pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    porcentajeCtrl.dispose();
    descripcionCtrl.dispose();

    if (ok == true) {
      _snack(
        'Tarifa actualizada correctamente.',
        icon: Icons.local_shipping_rounded,
      );
    } else if (ok == false && controller.error != null) {
      _snack(controller.error!, error: true);
    }
  }

  void _showMetodoDetalle(MetodoPagoModel metodo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleSheet(
        icon: Icons.account_balance_rounded,
        title: metodo.nombreVisible,
        subtitle: metodo.activo ? 'Método activo' : 'Método inactivo',
        color: metodo.activo ? Colors.green : Colors.orange,
        items: [
          _DetalleItem('Banco', metodo.banco),
          _DetalleItem('Moneda', metodo.moneda),
          _DetalleItem('Titular', metodo.titular),
          _DetalleItem('Cuenta', metodo.numeroCuenta),
          _DetalleItem('Orden', metodo.orden.toString()),
          _DetalleItem(
            'Descripción',
            metodo.descripcion.isEmpty ? 'N/D' : metodo.descripcion,
          ),
        ],
        primaryLabel: 'Editar',
        primaryIcon: Icons.edit_rounded,
        onPrimary: () {
          Navigator.pop(context);
          _formMetodo(metodo: metodo);
        },
        secondaryLabel: metodo.activo ? 'Desactivar' : 'Activar',
        secondaryIcon:
            metodo.activo ? Icons.pause_circle_rounded : Icons.check_circle,
        secondaryColor: metodo.activo ? Colors.redAccent : Colors.green,
        onSecondary: () {
          Navigator.pop(context);
          _toggleMetodo(metodo, !metodo.activo);
        },
      ),
    );
  }

  void _showTarifaDetalle(TarifaEnvioModel tarifa) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleSheet(
        icon: Icons.local_shipping_rounded,
        title: tarifa.nombreZona,
        subtitle: tarifa.activo ? 'Tarifa activa' : 'Tarifa inactiva',
        color: tarifa.activo ? Colors.green : Colors.orange,
        items: [
          _DetalleItem(
            'Porcentaje',
            '${tarifa.porcentajeEnvio.toStringAsFixed(2)}%',
          ),
          _DetalleItem(
            'Descripción',
            tarifa.descripcion.isEmpty ? 'N/D' : tarifa.descripcion,
          ),
        ],
        primaryLabel: 'Editar tarifa',
        primaryIcon: Icons.edit_rounded,
        onPrimary: () {
          Navigator.pop(context);
          _editarTarifa(tarifa);
        },
      ),
    );
  }

  void _changeTab(String value) {
    setState(() {
      tab = value;
      searchCtrl.clear();
      filtro = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMetodos = controller.metodos.length;
    final metodosActivos = controller.metodos.where((m) => m.activo).length;
    final totalTarifas = controller.tarifas.length;
    final tarifasActivas = controller.tarifas.where((t) => t.activo).length;

    return Scaffold(
      backgroundColor: MoodPalette.background,
      appBar: AppBar(
        backgroundColor: MoodPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoodPalette.text),
        title: const Text(
          'Configuración comercial',
          style: TextStyle(
            color: MoodPalette.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: controller.loading ? null : () => _refresh(message: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: tab == 'metodos'
          ? FloatingActionButton.extended(
              onPressed: () => _formMetodo(),
              backgroundColor: MoodPalette.pink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Agregar cuenta'),
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: controller.loading
            ? const Center(
                child: CircularProgressIndicator(color: MoodPalette.pink),
              )
            : controller.error != null
                ? _ErrorState(
                    message: controller.error!,
                    onRetry: _refresh,
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: MoodPalette.pink,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isDesktop = width >= 1100;
                        final isTablet = width >= 720 && width < 1100;

                        int crossAxisCount = 1;
                        double ratio = 1.34;

                        if (isDesktop) {
                          crossAxisCount = 3;
                          ratio = 1.32;
                        } else if (isTablet) {
                          crossAxisCount = 2;
                          ratio = 1.18;
                        }

                        final showMetodos = tab == 'metodos';

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: _Hero(
                                  totalMetodos: totalMetodos,
                                  totalTarifas: totalTarifas,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: _TabSelector(
                                  selected: tab,
                                  onChanged: _changeTab,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: _SearchBox(
                                  controller: searchCtrl,
                                  hint: showMetodos
                                      ? 'Buscar cuenta, banco, titular o moneda'
                                      : 'Buscar zona, porcentaje o descripción',
                                  onChanged: (value) {
                                    setState(() => filtro = value);
                                  },
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: _MetricPanel(
                                  totalMetodos: totalMetodos,
                                  metodosActivos: metodosActivos,
                                  totalTarifas: totalTarifas,
                                  tarifasActivas: tarifasActivas,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 18),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _SectionTitle(
                                  title: showMetodos
                                      ? 'Cuentas de transferencia'
                                      : 'Tarifas de envío por zona',
                                  subtitle: showMetodos
                                      ? 'Estas cuentas aparecen al cliente durante el checkout.'
                                      : 'Estos porcentajes calculan el envío del pedido.',
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 12),
                            ),
                            if (showMetodos && metodosFiltrados.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(
                                  icon: Icons.account_balance_wallet_outlined,
                                  title: 'No hay cuentas para mostrar',
                                  subtitle:
                                      'Agregá o ajustá el filtro de búsqueda.',
                                ),
                              )
                            else if (!showMetodos && tarifasFiltradas.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(
                                  icon: Icons.local_shipping_outlined,
                                  title: 'No hay tarifas para mostrar',
                                  subtitle:
                                      'Ajustá el filtro de búsqueda o revisá la configuración.',
                                ),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      if (showMetodos) {
                                        final metodo = metodosFiltrados[index];

                                        return _AnimatedItem(
                                          delay: index * 45,
                                          child: _MetodoCard(
                                            metodo: metodo,
                                            onTap: () =>
                                                _showMetodoDetalle(metodo),
                                            onEdit: () => _formMetodo(
                                              metodo: metodo,
                                            ),
                                            onToggle: (v) =>
                                                _toggleMetodo(metodo, v),
                                          ),
                                        );
                                      }

                                      final tarifa = tarifasFiltradas[index];

                                      return _AnimatedItem(
                                        delay: index * 45,
                                        child: _TarifaCard(
                                          tarifa: tarifa,
                                          onTap: () =>
                                              _showTarifaDetalle(tarifa),
                                          onEdit: () => _editarTarifa(tarifa),
                                        ),
                                      );
                                    },
                                    childCount: showMetodos
                                        ? metodosFiltrados.length
                                        : tarifasFiltradas.length,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: ratio,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final int totalMetodos;
  final int totalTarifas;

  const _Hero({
    required this.totalMetodos,
    required this.totalTarifas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: MoodPalette.mainGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [MoodPalette.cardShadow(.16)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: Icon(
              Icons.tune_rounded,
              color: Colors.white.withAlpha(25),
              size: 145,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Pagos y envíos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Administra cuentas bancarias y porcentajes de envío por zona desde un solo tablero.',
                style: TextStyle(
                  color: Colors.white.withAlpha(215),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroPill(
                    icon: Icons.account_balance_wallet_rounded,
                    text: '$totalMetodos cuentas',
                  ),
                  _HeroPill(
                    icon: Icons.local_shipping_rounded,
                    text: '$totalTarifas tarifas',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TabSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _TabOption(
        value: 'metodos',
        label: 'Métodos de pago',
        icon: Icons.account_balance_rounded,
        color: MoodPalette.pink,
      ),
      _TabOption(
        value: 'tarifas',
        label: 'Tarifas de envío',
        icon: Icons.local_shipping_rounded,
        color: MoodPalette.purple,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final active = selected == item.value;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: active,
              avatar: Icon(
                item.icon,
                size: 18,
                color: active ? Colors.white : item.color,
              ),
              selectedColor: item.color,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? item.color : Colors.grey.shade200,
              ),
              label: Text(
                item.label,
                style: TextStyle(
                  color: active ? Colors.white : MoodPalette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onSelected: (_) => onChanged(item.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TabOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _TabOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final int totalMetodos;
  final int metodosActivos;
  final int totalTarifas;
  final int tarifasActivas;

  const _MetricPanel({
    required this.totalMetodos,
    required this.metodosActivos,
    required this.totalTarifas,
    required this.tarifasActivas,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < 720;

        final cards = [
          _MetricCard(
            icon: Icons.account_balance_rounded,
            title: 'Cuentas',
            value: '$totalMetodos',
            color: MoodPalette.pink,
          ),
          _MetricCard(
            icon: Icons.check_circle_rounded,
            title: 'Cuentas activas',
            value: '$metodosActivos',
            color: Colors.green,
          ),
          _MetricCard(
            icon: Icons.local_shipping_rounded,
            title: 'Tarifas',
            value: '$totalTarifas',
            color: MoodPalette.purple,
          ),
          _MetricCard(
            icon: Icons.verified_rounded,
            title: 'Tarifas activas',
            value: '$tarifasActivas',
            color: Colors.orange,
          ),
        ];

        if (narrow) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(24),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 38,
          decoration: BoxDecoration(
            color: MoodPalette.pink,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoodPalette.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: MoodPalette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedItem extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedItem({
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay.clamp(0, 280)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MetodoCard extends StatefulWidget {
  final MetodoPagoModel metodo;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _MetodoCard({
    required this.metodo,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_MetodoCard> createState() => _MetodoCardState();
}

class _MetodoCardState extends State<_MetodoCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final metodo = widget.metodo;
    final color = metodo.activo ? MoodPalette.pink : Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.identity()..translate(0.0, hover ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hover ? color.withAlpha(80) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: hover ? color.withAlpha(35) : Colors.black.withAlpha(8),
              blurRadius: hover ? 20 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          metodo.activo ? MoodPalette.softPink : Colors.grey.shade200,
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        metodo.nombreVisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MoodPalette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Badge(
                      label: metodo.activo ? 'Activo' : 'Inactivo',
                      color: metodo.activo ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.person_rounded,
                  label: metodo.titular.isEmpty ? 'Sin titular' : metodo.titular,
                ),
                _InfoLine(
                  icon: Icons.numbers_rounded,
                  label: 'Cuenta: ${metodo.numeroCuenta}',
                ),
                _InfoLine(
                  icon: Icons.payments_rounded,
                  label: 'Moneda: ${metodo.moneda}',
                ),
                if (metodo.descripcion.isNotEmpty)
                  _InfoLine(
                    icon: Icons.notes_rounded,
                    label: metodo.descripcion,
                  ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MoodPalette.purple,
                          side: const BorderSide(color: MoodPalette.purple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onToggle(!metodo.activo),
                        icon: Icon(
                          metodo.activo
                              ? Icons.pause_circle_rounded
                              : Icons.check_circle_rounded,
                        ),
                        label: Text(metodo.activo ? 'Pausar' : 'Activar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              metodo.activo ? Colors.redAccent : Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarifaCard extends StatefulWidget {
  final TarifaEnvioModel tarifa;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _TarifaCard({
    required this.tarifa,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_TarifaCard> createState() => _TarifaCardState();
}

class _TarifaCardState extends State<_TarifaCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final tarifa = widget.tarifa;
    final color = tarifa.activo ? MoodPalette.pink : Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.identity()..translate(0.0, hover ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hover ? color.withAlpha(80) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: hover ? color.withAlpha(35) : Colors.black.withAlpha(8),
              blurRadius: hover ? 20 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: MoodPalette.softPurple,
                      child: Text(
                        '${tarifa.porcentajeEnvio.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: MoodPalette.deepPurple,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tarifa.nombreZona,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MoodPalette.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _Badge(
                      label: tarifa.activo ? 'Activa' : 'Inactiva',
                      color: tarifa.activo ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.percent_rounded,
                  label:
                      'Porcentaje: ${tarifa.porcentajeEnvio.toStringAsFixed(2)}%',
                ),
                _InfoLine(
                  icon: Icons.local_shipping_rounded,
                  label: tarifa.descripcion.isEmpty
                      ? 'Tarifa de envío configurada'
                      : tarifa.descripcion,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar tarifa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MoodPalette.pink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoLine({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleItem {
  final String label;
  final String value;

  const _DetalleItem(this.label, this.value);
}

class _DetalleSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<_DetalleItem> items;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final Color? secondaryColor;
  final VoidCallback? onSecondary;

  const _DetalleSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.secondaryColor,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: MoodPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withAlpha(25),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: MoodPalette.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: MoodPalette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                  color: MoodPalette.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.value.isEmpty ? 'N/D' : item.value,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: MoodPalette.text,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (onSecondary != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSecondary,
                          icon: Icon(secondaryIcon),
                          label: Text(secondaryLabel ?? 'Cambiar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                secondaryColor ?? Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPrimary,
                        icon: Icon(primaryIcon),
                        label: Text(primaryLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MoodPalette.purple,
                          side: const BorderSide(color: MoodPalette.purple),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

  const _MetodoPagoForm({
    this.metodo,
    required this.onSave,
  });

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

    final okConfirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: MoodPalette.pink.withAlpha(25),
                  child: Icon(
                    widget.metodo == null
                        ? Icons.add_card_rounded
                        : Icons.edit_rounded,
                    color: MoodPalette.pink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.metodo == null
                        ? 'Agregar cuenta'
                        : 'Guardar cambios',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            content: Text(
              widget.metodo == null
                  ? '¿Confirmás agregar esta cuenta?\n\nBanco: $banco\nMoneda: $moneda\nCuenta: ${cuenta.text.trim()}'
                  : '¿Confirmás actualizar esta cuenta?\n\nBanco: $banco\nMoneda: $moneda\nCuenta: ${cuenta.text.trim()}',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Confirmar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MoodPalette.pink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!okConfirm) return;

    setState(() => saving = true);

    final ok = await widget.onSave(
      banco: banco,
      moneda: moneda,
      titular: titular.text.trim(),
      numeroCuenta: cuenta.text.trim(),
      descripcion: descripcion.text.trim(),
      orden: int.tryParse(orden.text.trim()) ?? 1,
      activo: activo,
    );

    if (!mounted) return;

    setState(() => saving = false);

    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.metodo != null;

    final bancos = <String>{
      'BAC',
      'Lafise',
      'Banpro',
      if (banco.trim().isNotEmpty) banco,
    }.toList();

    final monedas = <String>{
      r'$',
      'C\$',
      if (moneda.trim().isNotEmpty) moneda,
    }.toList();

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: MoodPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: MoodPalette.pink.withAlpha(25),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_card_rounded,
                          color: MoodPalette.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'Editar cuenta' : 'Agregar cuenta',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            saving ? null : () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final narrow = constraints.maxWidth < 500;

                      final bancoField = DropdownButtonFormField<String>(
                        value: banco,
                        decoration: _dec(
                          'Banco',
                          Icons.account_balance_rounded,
                        ),
                        items: bancos
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text(b),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (v) => setState(() => banco = v ?? banco),
                      );

                      final monedaField = DropdownButtonFormField<String>(
                        value: moneda,
                        decoration: _dec(
                          'Moneda',
                          Icons.payments_rounded,
                        ),
                        items: monedas
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(m),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (v) => setState(() => moneda = v ?? moneda),
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            bancoField,
                            const SizedBox(height: 10),
                            monedaField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: bancoField),
                          const SizedBox(width: 10),
                          Expanded(child: monedaField),
                        ],
                      );
                    },
                  ),
                  _field(titular, 'A nombre de', Icons.person_rounded),
                  _field(cuenta, 'Número de cuenta', Icons.numbers_rounded),
                  _field(
                    descripcion,
                    'Descripción',
                    Icons.notes_rounded,
                    required: false,
                  ),
                  _field(
                    orden,
                    'Orden',
                    Icons.sort_rounded,
                    keyboard: TextInputType.number,
                  ),
                  SwitchListTile(
                    value: activo,
                    activeColor: MoodPalette.pink,
                    onChanged:
                        saving ? null : (v) => setState(() => activo = v),
                    title: const Text(
                      'Activo para clientes',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Si está apagado, el cliente no verá esta cuenta.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        saving
                            ? 'Guardando...'
                            : isEdit
                                ? 'Guardar cambios'
                                : 'Guardar cuenta',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MoodPalette.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = true,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: c,
        enabled: !saving,
        keyboardType: keyboard,
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null
            : null,
        decoration: _dec(label, icon),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 74, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withAlpha(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 14),
            const Text(
              'No se pudo cargar la configuración',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MoodPalette.pink,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}