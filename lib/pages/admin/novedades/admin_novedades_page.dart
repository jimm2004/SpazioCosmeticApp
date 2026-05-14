import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/admin/admin_novedades_controller.dart';
import '../../../models/novedad_model.dart';
import 'widgets/admin_novedad_form_sheet.dart';
import 'widgets/admin_novedades_widgets.dart';

class AdminNovedadesPage extends StatefulWidget {
  const AdminNovedadesPage({super.key});

  @override
  State<AdminNovedadesPage> createState() => _AdminNovedadesPageState();
}

class _AdminNovedadesPageState extends State<AdminNovedadesPage> {
  final AdminNovedadesController _controller = AdminNovedadesController();
  final TextEditingController _buscarCtrl = TextEditingController();

  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
    _controller.cargarNovedades(force: true, silent: true);
  }

  @override
  void dispose() {
    _controller.removeListener(_sync);
    _controller.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  void _notify(String message, {_NoticeType type = _NoticeType.info}) {
    if (!mounted) return;

    final color = switch (type) {
      _NoticeType.success => Colors.green.shade700,
      _NoticeType.error => Colors.redAccent,
      _NoticeType.warning => Colors.orange.shade700,
      _NoticeType.info => kNovedadText,
    };

    final icon = switch (type) {
      _NoticeType.success => Icons.check_circle_rounded,
      _NoticeType.error => Icons.error_rounded,
      _NoticeType.warning => Icons.warning_amber_rounded,
      _NoticeType.info => Icons.info_rounded,
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required IconData icon,
    Color color = kNovedadPink,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
              ],
            ),
            content: Text(message, style: const TextStyle(height: 1.4)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _refresh() async {
    await _controller.refreshForzado();
    if (!mounted) return;

    if (_controller.error == null) {
      _notify('Novedades actualizadas sin duplicar consultas.', type: _NoticeType.success);
    } else {
      _notify(_controller.error!, type: _NoticeType.error);
    }
  }

  Future<void> _confirmarRefresh() async {
    final ok = await _confirm(
      title: 'Actualizar novedades',
      message: 'Se consultará nuevamente el listado. Esta acción está protegida para no duplicar GET innecesarios.',
      action: 'Actualizar',
      icon: Icons.sync_rounded,
    );
    if (ok) await _refresh();
  }

  Future<void> _abrirFormulario({NovedadModel? novedad}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NovedadFormSheet(
        novedad: novedad,
        onBuscarProductos: _controller.buscarProductosParaNovedad,
        onSubmit: ({
          required String titulo,
          required String descripcion,
          XFile? foto,
          int? productoImagenId,
          String? enlaceUrl,
          required bool activo,
          required int orden,
        }) {
          if (novedad == null) {
            return _controller.crearNovedad(
              titulo: titulo,
              descripcion: descripcion,
              foto: foto,
              productoImagenId: productoImagenId,
              enlaceUrl: enlaceUrl,
              activo: activo,
              orden: orden,
            );
          }

          return _controller.actualizarNovedad(
            idNovedad: novedad.idNovedad,
            titulo: titulo,
            descripcion: descripcion,
            foto: foto,
            productoImagenId: productoImagenId,
            enlaceUrl: enlaceUrl,
            activo: activo,
            orden: orden,
          );
        },
      ),
    );

    if (!mounted) return;

    if (ok == true) {
      _notify(novedad == null ? 'Novedad creada correctamente.' : 'Novedad actualizada correctamente.', type: _NoticeType.success);
    } else if (_controller.error != null) {
      _notify(_controller.error!, type: _NoticeType.error);
    }
  }

  Future<void> _confirmarEliminar(NovedadModel novedad) async {
    final ok = await _confirm(
      title: 'Eliminar novedad',
      message: '¿Seguro que deseas eliminar "${novedad.titulo}"? Esta acción no se puede deshacer desde la vista.',
      action: 'Eliminar',
      icon: Icons.delete_outline_rounded,
      color: Colors.redAccent,
    );

    if (!ok) return;

    final eliminado = await _controller.eliminarNovedad(novedad);
    if (!mounted) return;

    if (eliminado) {
      _notify('Novedad eliminada correctamente.', type: _NoticeType.success);
    } else {
      _notify(_controller.error ?? 'No se pudo eliminar la novedad.', type: _NoticeType.error);
    }
  }

  Future<void> _cambiarEstado(NovedadModel novedad, bool value) async {
    final okConfirm = await _confirm(
      title: value ? 'Mostrar novedad' : 'Ocultar novedad',
      message: value
          ? 'La novedad volverá a mostrarse en el catálogo.'
          : 'La novedad se ocultará del catálogo, pero no se eliminará. Cero drama, control total.',
      action: value ? 'Mostrar' : 'Ocultar',
      icon: value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      color: value ? Colors.green.shade700 : Colors.orange.shade700,
    );

    if (!okConfirm) return;

    final ok = await _controller.cambiarEstado(novedad, value);
    if (!mounted) return;

    if (ok) {
      _notify(value ? 'Novedad visible en catálogo.' : 'Novedad ocultada del catálogo.', type: _NoticeType.success);
    } else {
      _notify(_controller.error ?? 'No se pudo cambiar el estado.', type: _NoticeType.error);
    }
  }

  void _limpiarBusqueda() {
    _buscarCtrl.clear();
    _controller.limpiarBusqueda();
    FocusScope.of(context).unfocus();
    _notify('Búsqueda limpiada. Tablero despejado, cero ruido.', type: _NoticeType.info);
  }

  void _cambiarFiltro(AdminNovedadFiltro filtro) {
    _controller.setFiltro(filtro);
    _notify('Filtro aplicado: ${adminNovedadFiltroLabel(filtro)} · ${_controller.filtradas.length} resultados.', type: _NoticeType.info);
  }

  void _cambiarVista() {
    setState(() => _isGridView = !_isGridView);
    _notify(_isGridView ? 'Vista cuadrícula activada.' : 'Vista lista activada.', type: _NoticeType.info);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kNovedadBg,
        appBar: AppBar(
          backgroundColor: kNovedadBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: kNovedadText),
          title: const Text(
            'Novedades',
            style: TextStyle(color: kNovedadText, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar novedades',
              onPressed: _controller.loading ? null : _confirmarRefresh,
              icon: const Icon(Icons.refresh_rounded, color: kNovedadPink),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _controller.saving ? null : () => _abrirFormulario(),
          backgroundColor: kNovedadPink,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Nueva novedad', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            int crossAxisCount;
            if (constraints.maxWidth >= 1320) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth >= 980) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth >= 680) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            if (_controller.loading && _controller.novedades.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: kNovedadPink));
            }

            final maxContentWidth = isWide ? 1280.0 : 980.0;
            final extra = constraints.maxWidth > maxContentWidth ? (constraints.maxWidth - maxContentWidth) / 2 : 0.0;
            final horizontal = extra + (isWide ? 24.0 : 16.0);
            final listPadding = EdgeInsets.fromLTRB(horizontal, 8, horizontal, 92);

            return RefreshIndicator(
              color: kNovedadPink,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                cacheExtent: 140,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: AdminNovedadesStatsHeader(
                      total: _controller.novedades.length,
                      filtradas: _controller.filtradas.length,
                      visibles: _controller.visibles,
                      ocultas: _controller.ocultas,
                      conImagen: _controller.conImagen,
                      sinImagen: _controller.sinImagen,
                      isWide: isWide,
                      onRefresh: _confirmarRefresh,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminNovedadSearchBox(
                      controller: _buscarCtrl,
                      onChanged: _controller.setQuery,
                      onClear: _limpiarBusqueda,
                      isWide: isWide,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminNovedadFilterRail(
                      filtro: _controller.filtro,
                      onChanged: _cambiarFiltro,
                      countFor: _controller.countFor,
                      isWide: isWide,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminNovedadesActionBar(
                      isGridView: _isGridView,
                      totalFiltradas: _controller.filtradas.length,
                      filtro: _controller.filtro,
                      onToggleView: _cambiarVista,
                      onRefresh: _confirmarRefresh,
                      isWide: isWide,
                    ),
                  ),
                  if (_controller.error != null && !_controller.loading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 10),
                        child: _ErrorBanner(message: _controller.error!, onClose: () => setState(() => _controller.error = null)),
                      ),
                    ),
                  if (_controller.filtradas.isEmpty)
                    const NovedadesEmptySliver()
                  else if (_isGridView)
                    NovedadesGridSliver(
                      novedades: _controller.filtradas,
                      crossAxisCount: crossAxisCount,
                      padding: listPadding,
                      onEdit: (n) => _abrirFormulario(novedad: n),
                      onDelete: _confirmarEliminar,
                      onToggle: _cambiarEstado,
                    )
                  else
                    NovedadesListSliver(
                      novedades: _controller.filtradas,
                      padding: listPadding,
                      onEdit: (n) => _abrirFormulario(novedad: n),
                      onDelete: _confirmarEliminar,
                      onToggle: _cambiarEstado,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w700))),
          IconButton(onPressed: onClose, icon: Icon(Icons.close_rounded, color: Colors.orange.shade700)),
        ],
      ),
    );
  }
}

enum _NoticeType { success, error, warning, info }
