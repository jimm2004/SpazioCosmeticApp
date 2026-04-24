import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/catalogo/catalogo_controller.dart';
import '../../widgets/shared/cart_modal.dart';
import '../../widgets/shared/footer_section.dart';
import '../../widgets/shared/product_detail_modal.dart';
import '../../widgets/shared/product_grid.dart';
import '../auth/auth_page.dart';

class CatalogoPage extends StatefulWidget {
  final String userName;

  const CatalogoPage({
    super.key,
    required this.userName,
  });

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final String phone = "50578496665";

  final AuthController _authController = AuthController();
  final CatalogoController _catalogoController = CatalogoController();

  late Future<List<Map<String, dynamic>>> _futureProductos;

  @override
  void initState() {
    super.initState();
    _futureProductos = _catalogoController.listarProductosParaGrid();
  }

  Future<void> _recargarProductos() async {
    setState(() {
      _futureProductos = _catalogoController.listarProductosParaGrid();
    });

    await _futureProductos;
  }

  Future<void> _launchWA(String msg) async {
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}',
    );

    final abierto = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!abierto) {
      debugPrint("No se pudo abrir WhatsApp");
    }
  }

  Future<void> _logout() async {
    try {
      await _authController.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _launchWA(
          "Hola Spazio Cosmetic, me gustaría consultar sobre sus productos.",
        ),
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE91E63),
        onRefresh: _recargarProductos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Text(
                'PROFESSIONAL COSMETICS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Catálogo Exclusivo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Descubre productos disponibles y realiza tus pedidos de forma rápida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureProductos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 60,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 60,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No se pudieron cargar los productos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _recargarProductos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final productos = snapshot.data ?? [];

                  if (productos.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 70,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay productos visibles todavía',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Solo se muestran productos activos y con foto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _recargarProductos,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE91E63),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar catálogo'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _recargarProductos,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Actualizar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ProductGrid(
                        productos: productos,
                        onProductTap: (producto) {
                          showDialog(
                            context: context,
                            builder: (_) => ProductDetailModal(
                              producto: producto,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 60),
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset(
            'assets/img/Logo.png',
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          if (MediaQuery.of(context).size.width > 800) ...[
            _navItem('Home'),
            _navItem('About Us'),
            _navItem('Shop'),
            _navItem('Contact Us'),
          ],
        ],
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              'Hola, ${widget.userName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFFE91E63),
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: CartController.instance,
          builder: (context, _) {
            final count = CartController.instance.totalItems;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CartModal(),
                    );
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE91E63),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.black),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _navItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}