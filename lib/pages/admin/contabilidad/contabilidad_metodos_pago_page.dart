import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

class ContabilidadMetodosPagoPage extends StatefulWidget {
  const ContabilidadMetodosPagoPage({super.key});

  @override
  State<ContabilidadMetodosPagoPage> createState() =>
      _ContabilidadMetodosPagoPageState();
}

class _ContabilidadMetodosPagoPageState
    extends State<ContabilidadMetodosPagoPage> {
  bool loading = true;
  String? error;
  String filtro = '';
  String estadoFiltro = 'todos';

  int? accionMetodoId;

  final TextEditingController buscarController = TextEditingController();

  List<MetodoPagoSimple> metodos = [];

  @override
  void initState() {
    super.initState();
    cargarMetodos();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  List<MetodoPagoSimple> get metodosFiltrados {
    final q = filtro.trim().toLowerCase();

    return metodos.where((m) {
      final coincideEstado = estadoFiltro == 'todos'
          ? true
          : estadoFiltro == 'activos'
              ? m.activo
              : !m.activo;

      final coincideTexto = q.isEmpty
          ? true
          : m.banco.toLowerCase().contains(q) ||
              m.moneda.toLowerCase().contains(q) ||
              m.tipoPago.toLowerCase().contains(q) ||
              m.titular.toLowerCase().contains(q) ||
              m.numeroCuenta.toLowerCase().contains(q) ||
              m.descripcion.toLowerCase().contains(q) ||
              '${m.orden}'.contains(q);

      return coincideEstado && coincideTexto;
    }).toList();
  }

  Future<void> cargarMetodos({bool mostrarMensaje = false}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get('/api/admin/metodos-pago');
      final data = _extraerLista(res);

      if (!mounted) return;

      setState(() {
        metodos = data
            .whereType<Map>()
            .map(
              (e) => MetodoPagoSimple.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      });

      if (mostrarMensaje) {
        _snack('Métodos de pago actualizados correctamente.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = _limpiarError(e);
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<dynamic> _extraerLista(Map<String, dynamic> res) {
    final data = res['data'];

    if (data is List) return data;

    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }

    if (data is Map && data['metodos'] is List) {
      return data['metodos'] as List;
    }

    if (res['metodos'] is List) {
      return res['metodos'] as List;
    }

    return [];
  }

  Future<void> abrirFormulario({MetodoPagoSimple? metodo}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _MetodoPagoFormSheet(
          metodo: metodo,
          onSave: (payload) async {
            if (metodo == null) {
              await ApiService().post(
                '/api/admin/metodos-pago',
                body: payload,
              );
            } else {
              await ApiService().put(
                '/api/admin/metodos-pago/${metodo.id}',
                body: payload,
              );
            }
          },
        );
      },
    );

    if (guardado == true) {
      _snack(
        metodo == null
            ? 'Método de pago agregado correctamente.'
            : 'Método de pago actualizado correctamente.',
        icon: metodo == null ? Icons.add_card_rounded : Icons.edit_rounded,
      );

      await cargarMetodos();
    }
  }

  Future<void> cambiarEstado(MetodoPagoSimple metodo, bool activo) async {
    if (metodo.id <= 0) {
      _snack('No se encontró el ID del método de pago.', error: true);
      return;
    }

    final confirmar = await _confirmarAccion(
      titulo: activo ? 'Activar método de pago' : 'Desactivar método de pago',
      mensaje: activo
          ? '¿Confirmás activar ${metodo.nombreVisible}?\n\nEl cliente podrá verlo en el checkout.'
          : '¿Confirmás desactivar ${metodo.nombreVisible}?\n\nEl cliente ya no verá este método al pagar.',
      icon: activo ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
      color: activo ? Colors.green : Colors.redAccent,
      textoBoton: activo ? 'Activar' : 'Desactivar',
    );

    if (confirmar != true) return;

    setState(() => accionMetodoId = metodo.id);

    try {
      await ApiService().post(
        '/api/admin/metodos-pago/${metodo.id}/estado',
        body: {
          'activo': activo ? 1 : 0,
        },
      );

      _snack(
        activo
            ? 'Método de pago activado correctamente.'
            : 'Método de pago desactivado correctamente.',
        error: !activo,
        icon: activo ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
      );

      await cargarMetodos();
    } catch (e) {
      _snack(_limpiarError(e), error: true);
    } finally {
      if (mounted) {
        setState(() => accionMetodoId = null);
      }
    }
  }

  Future<bool?> _confirmarAccion({
    required String titulo,
    required String mensaje,
    required IconData icon,
    required Color color,
    required String textoBoton,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
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
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            mensaje,
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
              label: Text(textoBoton),
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
        );
      },
    );
  }

  void verDetalleMetodo(MetodoPagoSimple metodo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DetalleMetodoPagoSheet(
          metodo: metodo,
          procesando: accionMetodoId == metodo.id,
          onEditar: () {
            Navigator.pop(context);
            abrirFormulario(metodo: metodo);
          },
          onToggle: () {
            Navigator.pop(context);
            cambiarEstado(metodo, !metodo.activo);
          },
        );
      },
    );
  }

  void cambiarFiltroEstado(String value) {
    if (estadoFiltro == value) return;

    setState(() {
      estadoFiltro = value;
      buscarController.clear();
      filtro = '';
    });
  }

  String _limpiarError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _snack(
    String msg, {
    bool error = false,
    IconData? icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: const Text(
          'Métodos de pago',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: loading
                ? null
                : () => cargarMetodos(mostrarMensaje: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => abrirFormulario(),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Agregar método'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: loading
            ? const _LoadingState()
            : error != null
                ? _ErrorState(
                    message: error!,
                    onRetry: cargarMetodos,
                  )
                : RefreshIndicator(
                    onRefresh: () => cargarMetodos(mostrarMensaje: true),
                    color: const Color(0xFFE91E63),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isDesktop = width >= 1100;
                        final isTablet = width >= 720 && width < 1100;

                        int crossAxisCount = 1;
                        double ratio = 1.35;

                        if (isDesktop) {
                          crossAxisCount = 3;
                          ratio = 1.34;
                        } else if (isTablet) {
                          crossAxisCount = 2;
                          ratio = 1.20;
                        }

                        return CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: _HeroMetodosPago(
                                  total: metodosFiltrados.length,
                                  estadoFiltro: estadoFiltro,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: _EstadoFilterBar(
                                  selected: estadoFiltro,
                                  onChanged: cambiarFiltroEstado,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: _SearchBox(
                                  controller: buscarController,
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
                                child: _MetricsRow(metodos: metodosFiltrados),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                            if (metodosFiltrados.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final metodo = metodosFiltrados[index];
                                      final procesando =
                                          accionMetodoId == metodo.id;

                                      return _AnimatedMetodoCard(
                                        delay: index * 45,
                                        child: _MetodoPagoCard(
                                          metodo: metodo,
                                          procesando: procesando,
                                          onDetalle: () =>
                                              verDetalleMetodo(metodo),
                                          onEdit: () => abrirFormulario(
                                            metodo: metodo,
                                          ),
                                          onToggle: (value) =>
                                              cambiarEstado(metodo, value),
                                        ),
                                      );
                                    },
                                    childCount: metodosFiltrados.length,
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
}

class MetodoPagoSimple {
  final int id;
  final String banco;
  final String moneda;
  final String tipoPago;
  final String titular;
  final String numeroCuenta;
  final String descripcion;
  final int orden;
  final bool activo;

  const MetodoPagoSimple({
    required this.id,
    required this.banco,
    required this.moneda,
    required this.tipoPago,
    required this.titular,
    required this.numeroCuenta,
    required this.descripcion,
    required this.orden,
    required this.activo,
  });

  factory MetodoPagoSimple.fromJson(Map<String, dynamic> json) {
    return MetodoPagoSimple(
      id: int.tryParse('${json['id']}') ?? 0,
      banco: '${json['banco'] ?? ''}',
      moneda: '${json['moneda'] ?? ''}',
      tipoPago: '${json['tipo_pago'] ?? 'transferencia'}',
      titular: '${json['titular'] ?? ''}',
      numeroCuenta: '${json['numero_cuenta'] ?? ''}',
      descripcion: '${json['descripcion'] ?? ''}',
      orden: int.tryParse('${json['orden']}') ?? 1,
      activo: _toBool(json['activo'], defaultValue: true),
    );
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;

    final text = '$value'.toLowerCase().trim();

    return text == '1' || text == 'true' || text == 'sí' || text == 'si';
  }

  String get nombreVisible {
    final bancoLabel = banco.isEmpty ? 'Banco' : banco;
    final monedaLabel = moneda.isEmpty ? 'Moneda' : moneda;
    return '$bancoLabel $monedaLabel';
  }

  Color get estadoColor {
    return activo ? Colors.green : Colors.orange;
  }

  IconData get estadoIcon {
    return activo ? Icons.check_circle_rounded : Icons.pause_circle_rounded;
  }

  String get estadoLabel {
    return activo ? 'Activo' : 'Inactivo';
  }
}

class _HeroMetodosPago extends StatelessWidget {
  final int total;
  final String estadoFiltro;

  const _HeroMetodosPago({
    required this.total,
    required this.estadoFiltro,
  });

  @override
  Widget build(BuildContext context) {
    final estadoTexto = estadoFiltro == 'activos'
        ? 'activos'
        : estadoFiltro == 'inactivos'
            ? 'inactivos'
            : 'registrados';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF15172B),
            Color(0xFF5E35B1),
            Color(0xFFE91E63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(50),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(
              Icons.account_balance_rounded,
              color: Colors.white.withAlpha(25),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Métodos de pago del cliente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Agrega, edita y controla las cuentas bancarias que verá el cliente al confirmar su pedido.',
                style: TextStyle(
                  color: Colors.white.withAlpha(210),
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
                    icon: Icons.list_alt_rounded,
                    text: '$total métodos $estadoTexto',
                  ),
                  const _HeroPill(
                    icon: Icons.security_rounded,
                    text: 'Control contable',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
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

class _EstadoFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _EstadoFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _FilterItem(
        value: 'todos',
        label: 'Todos',
        icon: Icons.all_inbox_rounded,
        color: const Color(0xFF5E35B1),
      ),
      _FilterItem(
        value: 'activos',
        label: 'Activos',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      _FilterItem(
        value: 'inactivos',
        label: 'Inactivos',
        icon: Icons.pause_circle_rounded,
        color: Colors.orange,
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
                  color: active ? Colors.white : const Color(0xFF2C3E50),
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

class _FilterItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por banco, cuenta, titular, moneda u orden',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final List<MetodoPagoSimple> metodos;

  const _MetricsRow({
    required this.metodos,
  });

  @override
  Widget build(BuildContext context) {
    final total = metodos.length;
    final activos = metodos.where((m) => m.activo).length;
    final inactivos = total - activos;
    final monedas = metodos.map((m) => m.moneda).where((m) => m.isNotEmpty).toSet().length;

    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < 720;

        final cards = [
          _MetricCard(
            icon: Icons.list_alt_rounded,
            title: 'Total',
            value: '$total',
            color: const Color(0xFF5E35B1),
          ),
          _MetricCard(
            icon: Icons.check_circle_rounded,
            title: 'Activos',
            value: '$activos',
            color: Colors.green,
          ),
          _MetricCard(
            icon: Icons.pause_circle_rounded,
            title: 'Inactivos',
            value: '$inactivos',
            color: Colors.orange,
          ),
          _MetricCard(
            icon: Icons.payments_rounded,
            title: 'Monedas',
            value: '$monedas',
            color: const Color(0xFFE91E63),
          ),
        ];

        if (narrow) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
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

class _AnimatedMetodoCard extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedMetodoCard({
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

class _MetodoPagoCard extends StatefulWidget {
  final MetodoPagoSimple metodo;
  final bool procesando;
  final VoidCallback onDetalle;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _MetodoPagoCard({
    required this.metodo,
    required this.procesando,
    required this.onDetalle,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_MetodoPagoCard> createState() => _MetodoPagoCardState();
}

class _MetodoPagoCardState extends State<_MetodoPagoCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.metodo;
    final color = m.activo ? const Color(0xFFE91E63) : Colors.grey;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, hover ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hover ? color.withAlpha(90) : Colors.grey.shade200,
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
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onDetalle,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withAlpha(22),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.nombreVisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusBadge(metodo: m),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.credit_card_rounded,
                  label: 'Tipo: ${m.tipoPago}',
                ),
                _InfoLine(
                  icon: Icons.person_rounded,
                  label: m.titular.isEmpty ? 'Sin titular' : m.titular,
                ),
                _InfoLine(
                  icon: Icons.numbers_rounded,
                  label: 'Cuenta: ${m.numeroCuenta}',
                ),
                _InfoLine(
                  icon: Icons.sort_rounded,
                  label: 'Orden: ${m.orden}',
                ),
                if (m.descripcion.isNotEmpty)
                  _InfoLine(
                    icon: Icons.notes_rounded,
                    label: m.descripcion,
                  ),
                const Spacer(),
                if (widget.procesando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5E35B1),
                            side: const BorderSide(color: Color(0xFF5E35B1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onToggle(!m.activo),
                          icon: Icon(
                            m.activo
                                ? Icons.pause_circle_rounded
                                : Icons.check_circle_rounded,
                          ),
                          label: Text(m.activo ? 'Pausar' : 'Activar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                m.activo ? Colors.redAccent : Colors.green,
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

class _StatusBadge extends StatelessWidget {
  final MetodoPagoSimple metodo;

  const _StatusBadge({
    required this.metodo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: metodo.estadoColor.withAlpha(22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        metodo.estadoLabel,
        style: TextStyle(
          color: metodo.estadoColor,
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

class _DetalleMetodoPagoSheet extends StatelessWidget {
  final MetodoPagoSimple metodo;
  final bool procesando;
  final VoidCallback onEditar;
  final VoidCallback onToggle;

  const _DetalleMetodoPagoSheet({
    required this.metodo,
    required this.procesando,
    required this.onEditar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = metodo.activo ? Colors.green : Colors.orange;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FB),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
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
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        metodo.nombreVisible,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetalleCard(
                  title: 'Información bancaria',
                  children: [
                    _DetalleItem('Banco', metodo.banco),
                    _DetalleItem('Moneda', metodo.moneda),
                    _DetalleItem('Tipo de pago', metodo.tipoPago),
                    _DetalleItem('Titular', metodo.titular),
                    _DetalleItem('Cuenta', metodo.numeroCuenta),
                  ],
                ),
                const SizedBox(height: 12),
                _DetalleCard(
                  title: 'Configuración',
                  children: [
                    _DetalleItem('Estado', metodo.estadoLabel),
                    _DetalleItem('Orden', '${metodo.orden}'),
                    _DetalleItem(
                      'Descripción',
                      metodo.descripcion.isEmpty ? 'N/D' : metodo.descripcion,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (procesando)
                  const CircularProgressIndicator()
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEditar,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5E35B1),
                            side: const BorderSide(color: Color(0xFF5E35B1)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onToggle,
                          icon: Icon(
                            metodo.activo
                                ? Icons.pause_circle_rounded
                                : Icons.check_circle_rounded,
                          ),
                          label: Text(metodo.activo ? 'Desactivar' : 'Activar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                metodo.activo ? Colors.redAccent : Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
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

class _DetalleCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetalleCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetalleItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetalleItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/D' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodoPagoFormSheet extends StatefulWidget {
  final MetodoPagoSimple? metodo;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const _MetodoPagoFormSheet({
    required this.metodo,
    required this.onSave,
  });

  @override
  State<_MetodoPagoFormSheet> createState() => _MetodoPagoFormSheetState();
}

class _MetodoPagoFormSheetState extends State<_MetodoPagoFormSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController bancoCtrl;
  late final TextEditingController titularCtrl;
  late final TextEditingController cuentaCtrl;
  late final TextEditingController descripcionCtrl;
  late final TextEditingController ordenCtrl;

  String moneda = 'C\$';
  String tipoPago = 'transferencia';
  bool activo = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final metodo = widget.metodo;

    bancoCtrl = TextEditingController(text: metodo?.banco ?? '');
    titularCtrl = TextEditingController(text: metodo?.titular ?? '');
    cuentaCtrl = TextEditingController(text: metodo?.numeroCuenta ?? '');
    descripcionCtrl = TextEditingController(text: metodo?.descripcion ?? '');
    ordenCtrl = TextEditingController(text: '${metodo?.orden ?? 1}');

    moneda = metodo?.moneda.isNotEmpty == true ? metodo!.moneda : 'C\$';
    tipoPago =
        metodo?.tipoPago.isNotEmpty == true ? metodo!.tipoPago : 'transferencia';
    activo = metodo?.activo ?? true;
  }

  @override
  void dispose() {
    bancoCtrl.dispose();
    titularCtrl.dispose();
    cuentaCtrl.dispose();
    descripcionCtrl.dispose();
    ordenCtrl.dispose();
    super.dispose();
  }

  Future<bool?> _confirmarGuardar(Map<String, dynamic> payload) {
    final isEdit = widget.metodo != null;

    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE91E63).withAlpha(25),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_card_rounded,
                  color: const Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEdit ? 'Guardar cambios' : 'Agregar método',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            isEdit
                ? '¿Confirmás actualizar este método de pago?\n\nBanco: ${payload['banco']}\nMoneda: ${payload['moneda']}\nCuenta: ${payload['numero_cuenta']}'
                : '¿Confirmás agregar este método de pago?\n\nBanco: ${payload['banco']}\nMoneda: ${payload['moneda']}\nCuenta: ${payload['numero_cuenta']}',
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
                backgroundColor: const Color(0xFFE91E63),
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
        );
      },
    );
  }

  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) return;

    final payload = {
      'banco': bancoCtrl.text.trim(),
      'moneda': moneda,
      'tipo_pago': tipoPago,
      'titular': titularCtrl.text.trim(),
      'numero_cuenta': cuentaCtrl.text.trim(),
      'descripcion': descripcionCtrl.text.trim(),
      'orden': int.tryParse(ordenCtrl.text.trim()) ?? 1,
      'activo': activo ? 1 : 0,
    };

    final confirmar = await _confirmarGuardar(payload);

    if (confirmar != true) return;

    setState(() => saving = true);

    try {
      await widget.onSave(payload);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.metodo != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F6FB),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
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
                        backgroundColor:
                            const Color(0xFFE91E63).withAlpha(25),
                        child: Icon(
                          isEdit ? Icons.edit_rounded : Icons.add_card_rounded,
                          color: const Color(0xFFE91E63),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'Editar método de pago' : 'Agregar método',
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
                  _field(
                    controller: bancoCtrl,
                    label: 'Banco',
                    icon: Icons.account_balance_rounded,
                    hint: 'BAC, Lafise, Banpro...',
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final narrow = constraints.maxWidth < 500;

                      final monedaField = DropdownButtonFormField<String>(
                        value: moneda,
                        decoration: _input(
                          'Moneda',
                          Icons.payments_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'C\$',
                            child: Text('C\$'),
                          ),
                          DropdownMenuItem(
                            value: '\$',
                            child: Text('\$'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => moneda = value);
                                }
                              },
                      );

                      final tipoField = DropdownButtonFormField<String>(
                        value: tipoPago,
                        decoration: _input(
                          'Tipo de pago',
                          Icons.credit_card_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'transferencia',
                            child: Text('Transferencia'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => tipoPago = value);
                                }
                              },
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            monedaField,
                            const SizedBox(height: 10),
                            tipoField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: monedaField),
                          const SizedBox(width: 10),
                          Expanded(child: tipoField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: titularCtrl,
                    label: 'Titular de la cuenta',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: cuentaCtrl,
                    label: 'Número de cuenta',
                    icon: Icons.numbers_rounded,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: descripcionCtrl,
                    label: 'Descripción',
                    icon: Icons.notes_rounded,
                    required: false,
                    hint: 'Cuenta BAC en córdobas...',
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: ordenCtrl,
                    label: 'Orden',
                    icon: Icons.sort_rounded,
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: activo,
                    activeColor: const Color(0xFFE91E63),
                    onChanged: saving
                        ? null
                        : (value) {
                            setState(() => activo = value);
                          },
                    title: const Text(
                      'Activo para clientes',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Si está apagado, el cliente no lo verá en checkout.',
                    ),
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
                        saving
                            ? 'Guardando...'
                            : isEdit
                                ? 'Guardar cambios'
                                : 'Agregar método',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
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
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = true,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !saving,
      keyboardType: keyboard,
      validator: required
          ? (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Campo obligatorio';
              }

              return null;
            }
          : null,
      decoration: _input(label, icon).copyWith(hintText: hint),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFE91E63),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              opacity: value.clamp(0, 1),
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 74,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay métodos para mostrar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Agregá BAC, Lafise, Banpro o la cuenta que usará el cliente.',
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
  final VoidCallback onRetry;

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
              'No se pudo cargar la información',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
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