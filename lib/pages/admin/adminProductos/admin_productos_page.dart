import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_productos_controller.dart';
import '../../../models/producto_admin_model.dart';
import 'admin_producto_detalle_page.dart';
import 'widgets/productos_widgets.dart';

class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({super.key});

  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final AdminProductosController _controller = AdminProductosController();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  bool isGridView = false;

  List<ProductoAdminModel> productos = [];
  List<ProductoAdminModel> filtrados = [];

  @override
  void initState() {
    super.initState();
    cargarProductos();
    searchController.addListener(_filtrar);
  }

  Future<void> cargarProductos() async {
    setState(() => loading = true);

    try {
      final lista = await _controller.obtenerProductos();

      if (!mounted) return;

      setState(() {
        productos = lista;
        filtrados = lista;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _filtrar() {
    final q = searchController.text.toLowerCase().trim();

    setState(() {
      filtrados = productos.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.descripcion.toLowerCase().contains(q) ||
            p.precioVenta.toString().contains(q) ||
            p.precioFinal.toString().contains(q);
      }).toList();
    });
  }

  void _limpiarBuscador() {
    searchController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _navegarDetalle(int idProducto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductoDetallePage(idProducto: idProducto),
      ),
    );

    await cargarProductos();
  }

  int get productosConFotos {
    return productos.where((p) => p.totalImagenes > 0).length;
  }

  int get productosSinFotos {
    return productos.where((p) => p.totalImagenes == 0).length;
  }

  int get productosVisibles {
    return productos.where((p) => p.activo ?? true).length;
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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
          title: const Text(
            'Productos Maestros',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  color: const Color(0xFF5E35B1),
                ),
                tooltip: isGridView ? 'Ver como lista' : 'Ver como cuadrícula',
                onPressed: () {
                  setState(() {
                    isGridView = !isGridView;
                  });
                },
              ),
            ),
          ],
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5E35B1)),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;

                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 5;
                  } else if (constraints.maxWidth >= 900) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth >= 600) {
                    crossAxisCount = 3;
                  }

                  return Column(
                    children: [
                      AdminProductosStatsHeader(
                        total: productos.length,
                        visibles: productosVisibles,
                        conFotos: productosConFotos,
                        sinFotos: productosSinFotos,
                      ),
                      AdminProductoSearchBox(
                        controller: searchController,
                        onClear: _limpiarBuscador,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xFF5E35B1),
                          onRefresh: cargarProductos,
                          child: filtrados.isEmpty
                              ? const ProductoEmptyState()
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: isGridView
                                      ? ProductoGridView(
                                          key: const ValueKey('grid'),
                                          productos: filtrados,
                                          crossAxisCount: crossAxisCount,
                                          onTapProducto: _navegarDetalle,
                                        )
                                      : ProductoListView(
                                          key: const ValueKey('list'),
                                          productos: filtrados,
                                          onTapProducto: _navegarDetalle,
                                        ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}