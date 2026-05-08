import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

class ContabilidadTarifasEnvioPage extends StatefulWidget {
  const ContabilidadTarifasEnvioPage({super.key});

  @override
  State<ContabilidadTarifasEnvioPage> createState() =>
      _ContabilidadTarifasEnvioPageState();
}

class _ContabilidadTarifasEnvioPageState
    extends State<ContabilidadTarifasEnvioPage> {
  bool loading = true;
  String? error;
  String filtro = '';
  String estadoFiltro = 'todos';

  int? accionTarifaId;

  final TextEditingController buscarController = TextEditingController();

  List<TarifaEnvioModel> tarifas = [];

  @override
  void initState() {
    super.initState();
    cargarTarifas();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  List<TarifaEnvioModel> get tarifasFiltradas {
    final q = filtro.trim().toLowerCase();

    return tarifas.where((t) {
      final coincideEstado = switch (estadoFiltro) {
        'activas' => t.activo,
        'inactivas' => !t.activo,
        'default' => t.esDefault,
        _ => true,
      };

      final coincideTexto = q.isEmpty
          ? true
          : t.nombreZona.toLowerCase().contains(q) ||
              t.descripcion.toLowerCase().contains(q) ||
              t.porcentajeEnvio.toString().contains(q) ||
              '${t.zonaId ?? ''}'.contains(q);

      return coincideEstado && coincideTexto;
    }).toList();
  }

  Future<void> cargarTarifas({bool mostrarMensaje = false}) async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get('/api/admin/tarifas-envio');
      final data = _extraerLista(res);

      if (!mounted) return;

      setState(() {
        tarifas = data
            .whereType<Map>()
            .map(
              (e) => TarifaEnvioModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      });

      if (mostrarMensaje) {
        _snack(
          'Tarifas actualizadas correctamente.',
          icon: Icons.refresh_rounded,
        );
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

    if (data is Map && data['tarifas'] is List) {
      return data['tarifas'] as List;
    }

    if (res['tarifas'] is List) {
      return res['tarifas'] as List;
    }

    return [];
  }

  Future<void> abrirFormulario({TarifaEnvioModel? tarifa}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TarifaEnvioFormSheet(
          tarifa: tarifa,
          onSave: (payload) async {
            if (tarifa == null) {
              await ApiService().post(
                '/api/admin/tarifas-envio',
                body: payload,
              );
            } else {
              await ApiService().put(
                '/api/admin/tarifas-envio/${tarifa.id}',
                body: payload,
              );
            }
          },
        );
      },
    );

    if (guardado == true) {
      _snack(
        tarifa == null
            ? 'Tarifa agregada correctamente.'
            : 'Tarifa actualizada correctamente.',
        icon: tarifa == null ? Icons.add_road_rounded : Icons.edit_rounded,
      );

      await cargarTarifas();
    }
  }

  Future<void> cambiarEstado(TarifaEnvioModel tarifa, bool activo) async {
    if (tarifa.id <= 0) {
      _snack('No se encontró el ID de la tarifa.', error: true);
      return;
    }

    if (tarifa.esDefault && !activo) {
      _snack(
        'No puedes desactivar la tarifa default. Primero asigná otra como default.',
        error: true,
        icon: Icons.warning_rounded,
      );
      return;
    }

    final confirmar = await _confirmarAccion(
      titulo: activo ? 'Activar tarifa' : 'Desactivar tarifa',
      mensaje: activo
          ? '¿Confirmás activar la tarifa "${tarifa.nombreVisible}"?\n\nEl sistema podrá usarla para calcular envíos.'
          : '¿Confirmás desactivar la tarifa "${tarifa.nombreVisible}"?\n\nEsta tarifa ya no se usará para calcular envíos.',
      icon: activo ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
      color: activo ? Colors.green : Colors.redAccent,
      textoBoton: activo ? 'Activar' : 'Desactivar',
    );

    if (confirmar != true) return;

    setState(() => accionTarifaId = tarifa.id);

    try {
      await ApiService().post(
        '/api/admin/tarifas-envio/${tarifa.id}/estado',
        body: {
          'activo': activo ? 1 : 0,
        },
      );

      _snack(
        activo
            ? 'Tarifa activada correctamente.'
            : 'Tarifa desactivada correctamente.',
        error: !activo,
        icon: activo ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
      );

      await cargarTarifas();
    } catch (e) {
      _snack(_limpiarError(e), error: true);
    } finally {
      if (mounted) {
        setState(() => accionTarifaId = null);
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

  void verDetalleTarifa(TarifaEnvioModel tarifa) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _DetalleTarifaEnvioSheet(
          tarifa: tarifa,
          procesando: accionTarifaId == tarifa.id,
          onEditar: () {
            Navigator.pop(context);
            abrirFormulario(tarifa: tarifa);
          },
          onToggle: () {
            Navigator.pop(context);
            cambiarEstado(tarifa, !tarifa.activo);
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
    String message, {
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
                message,
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
          'Tarifas de envío',
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
                : () => cargarTarifas(mostrarMensaje: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: loading ? null : () => abrirFormulario(),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_road_rounded),
        label: const Text('Agregar tarifa'),
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
                    onRetry: cargarTarifas,
                  )
                : RefreshIndicator(
                    onRefresh: () => cargarTarifas(mostrarMensaje: true),
                    color: const Color(0xFFE91E63),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isDesktop = width >= 1100;
                        final isTablet = width >= 720 && width < 1100;

                        int crossAxisCount = 1;
                        double ratio = 1.30;

                        if (isDesktop) {
                          crossAxisCount = 3;
                          ratio = 1.28;
                        } else if (isTablet) {
                          crossAxisCount = 2;
                          ratio = 1.14;
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
                                child: _HeroTarifas(
                                  total: tarifasFiltradas.length,
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
                                child: _MetricsRow(tarifas: tarifasFiltradas),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 16),
                            ),
                            if (tarifasFiltradas.isEmpty)
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
                                      final tarifa = tarifasFiltradas[index];
                                      final procesando =
                                          accionTarifaId == tarifa.id;

                                      return _AnimatedTarifaCard(
                                        delay: index * 45,
                                        child: _TarifaCard(
                                          tarifa: tarifa,
                                          procesando: procesando,
                                          onDetalle: () =>
                                              verDetalleTarifa(tarifa),
                                          onEdit: () => abrirFormulario(
                                            tarifa: tarifa,
                                          ),
                                          onToggle: (value) =>
                                              cambiarEstado(tarifa, value),
                                        ),
                                      );
                                    },
                                    childCount: tarifasFiltradas.length,
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

class TarifaEnvioModel {
  final int id;
  final int? zonaId;
  final String nombreZona;
  final double porcentajeEnvio;
  final bool esDefault;
  final String descripcion;
  final bool activo;

  const TarifaEnvioModel({
    required this.id,
    required this.zonaId,
    required this.nombreZona,
    required this.porcentajeEnvio,
    required this.esDefault,
    required this.descripcion,
    required this.activo,
  });

  factory TarifaEnvioModel.fromJson(Map<String, dynamic> json) {
    final zonaRaw = json['zona_id'];

    return TarifaEnvioModel(
      id: int.tryParse('${json['id']}') ?? 0,
      zonaId: zonaRaw == null || '$zonaRaw'.trim().isEmpty
          ? null
          : int.tryParse('$zonaRaw'),
      nombreZona: '${json['nombre_zona'] ?? ''}',
      porcentajeEnvio:
          double.tryParse('${json['porcentaje_envio']}'.replaceAll(',', '.')) ??
              0,
      esDefault: _toBool(json['es_default']),
      descripcion: '${json['descripcion'] ?? ''}',
      activo: _toBool(json['activo'], defaultValue: true),
    );
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;

    final text = '$value'.toLowerCase().trim();

    return text == '1' || text == 'true' || text == 'sí' || text == 'si';
  }

  String get nombreVisible {
    return nombreZona.isEmpty ? 'Sin nombre' : nombreZona;
  }

  Color get estadoColor {
    if (!activo) return Colors.orange;
    if (esDefault) return const Color(0xFFE91E63);
    return Colors.green;
  }

  IconData get estadoIcon {
    if (!activo) return Icons.pause_circle_rounded;
    if (esDefault) return Icons.star_rounded;
    return Icons.check_circle_rounded;
  }

  String get estadoLabel {
    if (!activo) return 'Inactiva';
    if (esDefault) return 'Default';
    return 'Activa';
  }
}

class _HeroTarifas extends StatelessWidget {
  final int total;
  final String estadoFiltro;

  const _HeroTarifas({
    required this.total,
    required this.estadoFiltro,
  });

  @override
  Widget build(BuildContext context) {
    final estadoTexto = estadoFiltro == 'activas'
        ? 'activas'
        : estadoFiltro == 'inactivas'
            ? 'inactivas'
            : estadoFiltro == 'default'
                ? 'default'
                : 'registradas';

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
              Icons.local_shipping_rounded,
              color: Colors.white.withAlpha(25),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.percent_rounded,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Porcentaje de cobro por envío',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Administra las tarifas que el sistema usará para calcular el envío según la zona del cliente.',
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
                    text: '$total tarifas $estadoTexto',
                  ),
                  const _HeroPill(
                    icon: Icons.calculate_rounded,
                    text: 'Cálculo automático',
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
        label: 'Todas',
        icon: Icons.all_inbox_rounded,
        color: const Color(0xFF5E35B1),
      ),
      _FilterItem(
        value: 'activas',
        label: 'Activas',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      _FilterItem(
        value: 'inactivas',
        label: 'Inactivas',
        icon: Icons.pause_circle_rounded,
        color: Colors.orange,
      ),
      _FilterItem(
        value: 'default',
        label: 'Default',
        icon: Icons.star_rounded,
        color: const Color(0xFFE91E63),
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
        hintText: 'Buscar por zona, descripción, ID o porcentaje',
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
  final List<TarifaEnvioModel> tarifas;

  const _MetricsRow({
    required this.tarifas,
  });

  @override
  Widget build(BuildContext context) {
    final total = tarifas.length;
    final activas = tarifas.where((t) => t.activo).length;
    final inactivas = total - activas;
    final defaults = tarifas.where((t) => t.esDefault).length;

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
            title: 'Activas',
            value: '$activas',
            color: Colors.green,
          ),
          _MetricCard(
            icon: Icons.pause_circle_rounded,
            title: 'Inactivas',
            value: '$inactivas',
            color: Colors.orange,
          ),
          _MetricCard(
            icon: Icons.star_rounded,
            title: 'Default',
            value: '$defaults',
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

class _AnimatedTarifaCard extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedTarifaCard({
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

class _TarifaCard extends StatefulWidget {
  final TarifaEnvioModel tarifa;
  final bool procesando;
  final VoidCallback onDetalle;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _TarifaCard({
    required this.tarifa,
    required this.procesando,
    required this.onDetalle,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_TarifaCard> createState() => _TarifaCardState();
}

class _TarifaCardState extends State<_TarifaCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tarifa;

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
            color: hover ? t.estadoColor.withAlpha(90) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: hover
                  ? t.estadoColor.withAlpha(35)
                  : Colors.black.withAlpha(8),
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
                      backgroundColor: t.estadoColor.withAlpha(22),
                      child: Icon(
                        t.estadoIcon,
                        color: t.estadoColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.nombreVisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusBadge(tarifa: t),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.percent_rounded,
                  label: 'Cobro: ${t.porcentajeEnvio.toStringAsFixed(2)}%',
                ),
                _InfoLine(
                  icon: Icons.map_rounded,
                  label: t.zonaId == null ? 'Zona: Default/resto' : 'ID zona: ${t.zonaId}',
                ),
                _InfoLine(
                  icon: Icons.star_rounded,
                  label: t.esDefault ? 'Tarifa por defecto' : 'Tarifa por zona',
                ),
                if (t.descripcion.isNotEmpty)
                  _InfoLine(
                    icon: Icons.notes_rounded,
                    label: t.descripcion,
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
                          onPressed: () => widget.onToggle(!t.activo),
                          icon: Icon(
                            t.activo
                                ? Icons.pause_circle_rounded
                                : Icons.check_circle_rounded,
                          ),
                          label: Text(t.activo ? 'Pausar' : 'Activar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                t.activo ? Colors.redAccent : Colors.green,
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
  final TarifaEnvioModel tarifa;

  const _StatusBadge({
    required this.tarifa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: tarifa.estadoColor.withAlpha(22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        tarifa.estadoLabel,
        style: TextStyle(
          color: tarifa.estadoColor,
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

class _DetalleTarifaEnvioSheet extends StatelessWidget {
  final TarifaEnvioModel tarifa;
  final bool procesando;
  final VoidCallback onEditar;
  final VoidCallback onToggle;

  const _DetalleTarifaEnvioSheet({
    required this.tarifa,
    required this.procesando,
    required this.onEditar,
    required this.onToggle,
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
                      backgroundColor: tarifa.estadoColor.withAlpha(25),
                      child: Icon(
                        tarifa.estadoIcon,
                        color: tarifa.estadoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tarifa.nombreVisible,
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
                  title: 'Datos de la tarifa',
                  children: [
                    _DetalleItem('Zona', tarifa.nombreVisible),
                    _DetalleItem(
                      'Porcentaje',
                      '${tarifa.porcentajeEnvio.toStringAsFixed(2)}%',
                    ),
                    _DetalleItem(
                      'ID zona',
                      tarifa.zonaId?.toString() ?? 'Default/resto',
                    ),
                    _DetalleItem(
                      'Tipo',
                      tarifa.esDefault ? 'Tarifa por defecto' : 'Tarifa por zona',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetalleCard(
                  title: 'Configuración',
                  children: [
                    _DetalleItem('Estado', tarifa.estadoLabel),
                    _DetalleItem(
                      'Descripción',
                      tarifa.descripcion.isEmpty ? 'N/D' : tarifa.descripcion,
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
                            tarifa.activo
                                ? Icons.pause_circle_rounded
                                : Icons.check_circle_rounded,
                          ),
                          label: Text(tarifa.activo ? 'Desactivar' : 'Activar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                tarifa.activo ? Colors.redAccent : Colors.green,
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

class _TarifaEnvioFormSheet extends StatefulWidget {
  final TarifaEnvioModel? tarifa;
  final Future<void> Function(Map<String, dynamic> payload) onSave;

  const _TarifaEnvioFormSheet({
    required this.tarifa,
    required this.onSave,
  });

  @override
  State<_TarifaEnvioFormSheet> createState() => _TarifaEnvioFormSheetState();
}

class _TarifaEnvioFormSheetState extends State<_TarifaEnvioFormSheet> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController zonaIdCtrl;
  late final TextEditingController nombreZonaCtrl;
  late final TextEditingController porcentajeCtrl;
  late final TextEditingController descripcionCtrl;

  bool esDefault = false;
  bool activo = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final tarifa = widget.tarifa;

    zonaIdCtrl = TextEditingController(
      text: tarifa?.zonaId?.toString() ?? '',
    );
    nombreZonaCtrl = TextEditingController(text: tarifa?.nombreZona ?? '');
    porcentajeCtrl = TextEditingController(
      text: tarifa == null ? '' : tarifa.porcentajeEnvio.toStringAsFixed(2),
    );
    descripcionCtrl = TextEditingController(text: tarifa?.descripcion ?? '');

    esDefault = tarifa?.esDefault ?? false;
    activo = tarifa?.activo ?? true;
  }

  @override
  void dispose() {
    zonaIdCtrl.dispose();
    nombreZonaCtrl.dispose();
    porcentajeCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<bool?> _confirmarGuardar(Map<String, dynamic> payload) {
    final isEdit = widget.tarifa != null;

    return showDialog<bool>(
      context: context,
      builder: (_) {
        final esDefaultLocal = payload['es_default'] == 1;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE91E63).withAlpha(25),
                child: Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_road_rounded,
                  color: const Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEdit ? 'Guardar cambios' : 'Agregar tarifa',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            isEdit
                ? '¿Confirmás actualizar esta tarifa?\n\nZona: ${payload['nombre_zona']}\nPorcentaje: ${payload['porcentaje_envio']}%\nDefault: ${esDefaultLocal ? 'Sí' : 'No'}'
                : '¿Confirmás agregar esta tarifa?\n\nZona: ${payload['nombre_zona']}\nPorcentaje: ${payload['porcentaje_envio']}%\nDefault: ${esDefaultLocal ? 'Sí' : 'No'}',
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

    final zonaIdText = zonaIdCtrl.text.trim();

    final payload = {
      'zona_id': esDefault || zonaIdText.isEmpty
          ? null
          : int.tryParse(zonaIdText),
      'nombre_zona': nombreZonaCtrl.text.trim(),
      'porcentaje_envio':
          double.tryParse(porcentajeCtrl.text.trim().replaceAll(',', '.')) ??
              0,
      'es_default': esDefault ? 1 : 0,
      'descripcion': descripcionCtrl.text.trim(),
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
    final isEdit = widget.tarifa != null;

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
                          isEdit ? Icons.edit_rounded : Icons.add_road_rounded,
                          color: const Color(0xFFE91E63),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'Editar tarifa' : 'Agregar tarifa',
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
                    controller: nombreZonaCtrl,
                    label: 'Nombre de zona',
                    icon: Icons.map_rounded,
                    hint: 'Zona Norte, Zona Managua, Resto de zonas...',
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: porcentajeCtrl,
                    label: 'Porcentaje de envío',
                    icon: Icons.percent_rounded,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: 'Ejemplo: 5, 8, 10',
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: zonaIdCtrl,
                    label: 'ID de zona',
                    icon: Icons.numbers_rounded,
                    required: false,
                    keyboard: TextInputType.number,
                    hint: 'Opcional. Vacío para tarifa default/resto.',
                  ),
                  const SizedBox(height: 10),
                  _field(
                    controller: descripcionCtrl,
                    label: 'Descripción',
                    icon: Icons.notes_rounded,
                    required: false,
                    hint: 'Envío Zona Norte: 5% del subtotal',
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: esDefault,
                    activeColor: Colors.orange,
                    onChanged: saving
                        ? null
                        : (value) {
                            setState(() {
                              esDefault = value;

                              if (value) {
                                zonaIdCtrl.clear();
                              }
                            });
                          },
                    title: const Text(
                      'Tarifa por defecto',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Se usará cuando el cliente no tenga una zona específica.',
                    ),
                  ),
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
                      'Si está apagado, no se usará para calcular envíos.',
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
                                : 'Agregar tarifa',
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 74,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay tarifas para mostrar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Agregá las zonas y porcentajes que usará el cliente en checkout.',
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