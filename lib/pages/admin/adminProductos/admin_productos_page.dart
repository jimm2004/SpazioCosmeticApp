import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_productos_controller.dart';
import '../../../models/producto_admin_model.dart';
import 'admin_producto_detalle_page.dart';
import 'widgets/productos_widgets.dart';

const _adminPurple = Color(0xFF5E35B1);
const _adminText = Color(0xFF2C3E50);
const _adminBg = Color(0xFFF5F7FA);

class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({super.key});

  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final AdminProductosController _controller = AdminProductosController();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  bool isGridView = true;
  bool _requestInProgress = false;
  DateTime? _lastRequestAt;
  AdminProductoFiltro filtroActivo = AdminProductoFiltro.todos;

  List<ProductoAdminModel> productos = [];
  List<ProductoAdminModel> filtrados = [];

  @override
  void initState() {
    super.initState();
    cargarProductos(showSuccess: false, force: true);
    searchController.addListener(_aplicarFiltros);
  }

  Future<void> cargarProductos({bool showSuccess = true, bool force = false}) async {
    if (_requestInProgress) {
      if (showSuccess) {
        _notify('Ya hay una actualización en curso. Evitamos duplicar GET para cuidar la API.', type: _NoticeType.info);
      }
      return;
    }

    final now = DateTime.now();
    final diff = _lastRequestAt == null ? null : now.difference(_lastRequestAt!);
    if (!force && diff != null && diff.inSeconds < 4) {
      if (showSuccess) {
        _notify('Actualización omitida: espera ${4 - diff.inSeconds}s para no saturar el servidor.', type: _NoticeType.warning);
      }
      return;
    }

    _requestInProgress = true;
    _lastRequestAt = now;
    if (mounted) setState(() => loading = true);

    try {
      final lista = await _controller.obtenerProductos();

      if (!mounted) return;

      setState(() {
        productos = lista;
        loading = false;
      });
      _aplicarFiltros(showSetState: false);

      if (showSuccess) {
        _notify(
          'Catálogo actualizado: ${lista.length} productos cargados sin duplicar consultas.',
          type: _NoticeType.success,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      _notify(e.toString().replaceFirst('Exception: ', ''), type: _NoticeType.error);
    } finally {
      _requestInProgress = false;
    }
  }

  void _aplicarFiltros({bool showSetState = true}) {
    final q = searchController.text.toLowerCase().trim();

    bool matchesText(ProductoAdminModel p) {
      if (q.isEmpty) return true;
      return p.nombre.toLowerCase().contains(q) ||
          p.descripcion.toLowerCase().contains(q) ||
          p.precioVenta.toString().contains(q) ||
          p.precioFinal.toString().contains(q) ||
          p.cantidadStock.toString().contains(q);
    }

    bool matchesFilter(ProductoAdminModel p) {
      switch (filtroActivo) {
        case AdminProductoFiltro.todos:
          return true;
        case AdminProductoFiltro.visibles:
          return p.activo ?? true;
        case AdminProductoFiltro.ocultos:
          return !(p.activo ?? true);
        case AdminProductoFiltro.conFotos:
          return p.totalImagenes > 0;
        case AdminProductoFiltro.sinFotos:
          return p.totalImagenes == 0;
        case AdminProductoFiltro.sinStock:
          return p.cantidadStock <= 0;
      }
    }

    final next = productos.where((p) => matchesText(p) && matchesFilter(p)).toList();

    if (showSetState) {
      setState(() => filtrados = next);
    } else {
      filtrados = next;
      if (mounted) setState(() {});
    }
  }

  void _limpiarBuscador() {
    searchController.clear();
    FocusScope.of(context).unfocus();
    _notify('Búsqueda limpiada. Vista reiniciada como tablero de control.', type: _NoticeType.info);
  }

  Future<void> _navegarDetalle(int idProducto) async {
    final producto = productos.where((p) => p.idProducto == idProducto).cast<ProductoAdminModel?>().firstOrNull;
    _notify(
      producto == null ? 'Abriendo detalle del producto...' : 'Abriendo ${producto.nombre}.',
      type: _NoticeType.info,
    );

    final huboCambios = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminProductoDetallePage(idProducto: idProducto)),
    );

    if (huboCambios == true) {
      await cargarProductos(showSuccess: false, force: true);
      _notify('Cambios sincronizados con la vista principal.', type: _NoticeType.success);
    } else {
      _notify('Regresaste sin cambios. No se hizo GET extra; API feliz, negocio feliz.', type: _NoticeType.info);
    }
  }

  void _cambiarFiltro(AdminProductoFiltro filtro) {
    setState(() => filtroActivo = filtro);
    _aplicarFiltros(showSetState: false);
    _notify('Filtro aplicado: ${adminProductoFiltroLabel(filtro)} · ${filtrados.length} resultados.', type: _NoticeType.info);
  }

  void _cambiarVista() {
    setState(() => isGridView = !isGridView);
    _notify(isGridView ? 'Vista cuadrícula activada.' : 'Vista lista activada.', type: _NoticeType.info);
  }

  Future<void> _confirmarRefresh() async {
    final ok = await _confirm(
      title: 'Actualizar catálogo',
      message: 'Se consultará nuevamente el listado de productos. Ideal para traer fotos, precios y visibilidad recién cambiados.',
      action: 'Actualizar',
      icon: Icons.sync_rounded,
    );
    if (ok) await cargarProductos(force: true);
  }

  int get productosConFotos => productos.where((p) => p.totalImagenes > 0).length;
  int get productosSinFotos => productos.where((p) => p.totalImagenes == 0).length;
  int get productosVisibles => productos.where((p) => p.activo ?? true).length;
  int get productosOcultos => productos.where((p) => !(p.activo ?? true)).length;
  int get productosSinStock => productos.where((p) => p.cantidadStock <= 0).length;

  int _countFor(AdminProductoFiltro filtro) {
    switch (filtro) {
      case AdminProductoFiltro.todos:
        return productos.length;
      case AdminProductoFiltro.visibles:
        return productosVisibles;
      case AdminProductoFiltro.ocultos:
        return productosOcultos;
      case AdminProductoFiltro.conFotos:
        return productosConFotos;
      case AdminProductoFiltro.sinFotos:
        return productosSinFotos;
      case AdminProductoFiltro.sinStock:
        return productosSinStock;
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _adminPurple.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: _adminPurple),
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
                  backgroundColor: _adminPurple,
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

  void _notify(String message, {required _NoticeType type}) {
    if (!mounted) return;
    final color = switch (type) {
      _NoticeType.success => Colors.green.shade700,
      _NoticeType.error => Colors.redAccent,
      _NoticeType.warning => Colors.orange.shade700,
      _NoticeType.info => _adminText,
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _adminBg,
        appBar: AppBar(
          backgroundColor: _adminBg,
          elevation: 0,
          iconTheme: const IconThemeData(color: _adminText),
          title: const Text(
            'Productos Maestros',
            style: TextStyle(color: _adminText, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar catálogo',
              onPressed: _confirmarRefresh,
              icon: const Icon(Icons.refresh_rounded, color: _adminPurple),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            int crossAxisCount;
            if (constraints.maxWidth >= 1320) {
              crossAxisCount = 5;
            } else if (constraints.maxWidth >= 1040) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth >= 720) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            if (loading) {
              return const Center(child: CircularProgressIndicator(color: _adminPurple));
            }

            final maxContentWidth = isWide ? 1280.0 : 980.0;
            final extra = constraints.maxWidth > maxContentWidth ? (constraints.maxWidth - maxContentWidth) / 2 : 0.0;
            final horizontal = extra + (isWide ? 24.0 : 16.0);
            final listPadding = EdgeInsets.fromLTRB(horizontal, 8, horizontal, 28);

            return RefreshIndicator(
              color: _adminPurple,
              onRefresh: () => cargarProductos(force: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                cacheExtent: 120,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: AdminProductosStatsHeader(
                      total: productos.length,
                      filtrados: filtrados.length,
                      visibles: productosVisibles,
                      conFotos: productosConFotos,
                      sinFotos: productosSinFotos,
                      sinStock: productosSinStock,
                      isWide: isWide,
                      onRefresh: _confirmarRefresh,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminProductoSearchBox(
                      controller: searchController,
                      onClear: _limpiarBuscador,
                      onSubmitted: (_) => _notify('Búsqueda aplicada: ${filtrados.length} resultados.', type: _NoticeType.info),
                      isWide: isWide,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminProductoFilterRail(
                      filtro: filtroActivo,
                      onChanged: _cambiarFiltro,
                      countFor: _countFor,
                      isWide: isWide,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AdminProductosActionBar(
                      isGridView: isGridView,
                      totalFiltrados: filtrados.length,
                      filtro: filtroActivo,
                      onToggleView: _cambiarVista,
                      onRefresh: _confirmarRefresh,
                      isWide: isWide,
                    ),
                  ),
                  if (filtrados.isEmpty)
                    const ProductoEmptyStateSliver()
                  else if (isGridView)
                    ProductoGridSliver(
                      productos: filtrados,
                      crossAxisCount: crossAxisCount,
                      onTapProducto: _navegarDetalle,
                      padding: listPadding,
                      isWide: isWide,
                    )
                  else
                    ProductoListSliver(
                      productos: filtrados,
                      onTapProducto: _navegarDetalle,
                      padding: listPadding,
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

enum _NoticeType { success, error, warning, info }

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
