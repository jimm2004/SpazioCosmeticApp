import 'package:flutter/material.dart';
import '../../../controllers/admin/admin_productos_controller.dart';
import '../../../models/producto_admin_model.dart';
import 'admin_producto_detalle_page.dart';

class AdminProductosPage extends StatefulWidget {
  const AdminProductosPage({super.key});

  @override
  State<AdminProductosPage> createState() => _AdminProductosPageState();
}

class _AdminProductosPageState extends State<AdminProductosPage> {
  final AdminProductosController _controller = AdminProductosController();

  bool loading = true;
  List<ProductoAdminModel> productos = [];
  List<ProductoAdminModel> filtrados = [];
  final TextEditingController searchController = TextEditingController();

  // Variable para alternar entre vista de Cuadrícula y Lista
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    cargarProductos();
    // El listener llama a _filtrar cada vez que el texto cambia
    searchController.addListener(_filtrar);
  }

  Future<void> cargarProductos() async {
    setState(() => loading = true);

    try {
      final lista = await _controller.obtenerProductos();

      setState(() {
        productos = lista;
        filtrados = lista;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _filtrar() {
    final q = searchController.text.toLowerCase().trim();

    setState(() {
      filtrados = productos.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.descripcion.toLowerCase().contains(q);
      }).toList();
    });
  }

  // FUNCIÓN ÚTIL: Limpiar buscador y ocultar teclado
  void _limpiarBuscador() {
    searchController.clear(); // Esto dispara _filtrar() automáticamente
    FocusScope.of(context).unfocus(); // Oculta el teclado en móviles
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector envuelve el Scaffold para que al tocar cualquier parte de la pantalla 
    // que no sea el teclado, este se oculte mágicamente.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Fondo gris claro premium
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
            // BOTÓN PARA ALTERNAR VISTAS
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF5E35B1)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Cálculo de columnas basado en el ancho de la pantalla (Responsividad)
                  int crossAxisCount = 2; // Teléfonos por defecto
                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 5; // Monitores grandes
                  } else if (constraints.maxWidth >= 900) {
                    crossAxisCount = 4; // Laptops / Monitores normales
                  } else if (constraints.maxWidth >= 600) {
                    crossAxisCount = 3; // Tablets
                  }

                  return Column(
                    children: [
                      // BUSCADOR MODERNO CENTRADO
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar producto...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5E35B1)),
                                  // FUNCIÓN ÚTIL: Botón de Limpiar dinámico
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.grey),
                                          onPressed: _limpiarBuscador,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // LISTA / CUADRÍCULA DE PRODUCTOS O ESTADO VACÍO
                      Expanded(
                        child: RefreshIndicator(
                          color: const Color(0xFF5E35B1),
                          onRefresh: cargarProductos,
                          child: filtrados.isEmpty
                              ? _buildEmptyState() // FUNCIÓN ÚTIL: Mostrar cuando no hay resultados
                              : isGridView
                                  ? _buildGridView(crossAxisCount)
                                  : _buildListView(),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // ========================================================
  // WIDGET AUXILIAR: ESTADO VACÍO (Empty State)
  // ========================================================
  Widget _buildEmptyState() {
    // Usamos un ListView para que el RefreshIndicator (Swipe to refresh) siga funcionando
    // incluso cuando no hay elementos en la pantalla.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron productos',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta buscar con otra palabra',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // WIDGET: VISTA DE LISTA (Acoplada al centro en PC)
  // ========================================================
  Widget _buildListView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800), // Evita que se estire demasiado en PC
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filtrados.length,
          itemBuilder: (context, index) {
            final p = filtrados[index];
            final bool esVisible = p.activo ?? true;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    FocusScope.of(context).unfocus(); // Oculta el teclado al abrir el detalle
                    _navegarDetalle(p.idProducto);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // IMAGEN REDONDEADA
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: p.imagenUrl != null && p.imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    p.imagenUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.inventory_2, color: Colors.grey, size: 30),
                        ),
                        const SizedBox(width: 16),
                        // TEXTOS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Precio: \$${p.precioVenta.toStringAsFixed(2)}  •  Stock: ${p.cantidadStock}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBadge(esVisible),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================================================
  // WIDGET: VISTA DE CUADRÍCULA (Dinámica)
  // ========================================================
  Widget _buildGridView(int crossAxisCount) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200), // Límite para pantallas ultra anchas
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filtrados.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75, // Proporción altura/anchura de las tarjetas
          ),
          itemBuilder: (context, index) {
            final p = filtrados[index];
            final bool esVisible = p.activo ?? true;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    FocusScope.of(context).unfocus(); // Oculta el teclado al abrir el detalle
                    _navegarDetalle(p.idProducto);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGEN DE LA CUADRÍCULA
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: p.imagenUrl != null && p.imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  child: Image.network(
                                    p.imagenUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                                  ),
                                )
                              : const Icon(Icons.inventory_2, color: Colors.grey, size: 40),
                        ),
                      ),
                      // TEXTOS DE LA CUADRÍCULA
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${p.precioVenta.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stock: ${p.cantidadStock}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildBadge(esVisible),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: Etiqueta de visibilidad
  Widget _buildBadge(bool esVisible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: esVisible
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        esVisible ? 'Visible' : 'Oculto',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: esVisible ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  // NAVEGACIÓN
  Future<void> _navegarDetalle(int idProducto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductoDetallePage(idProducto: idProducto),
      ),
    );
    await cargarProductos();
  }
}