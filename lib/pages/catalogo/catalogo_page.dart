import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/catalogo/cart_controller.dart';
import '../../controllers/catalogo/catalogo_controller.dart';
import 'widgets/cart_modal.dart';
import 'widgets/footer_section.dart';
import 'widgets/product_detail_modal.dart';
import 'widgets/product_grid.dart';
import '../auth/auth_page.dart';

class CatalogoPage extends StatefulWidget {
  final String userName;

  const CatalogoPage({super.key, required this.userName});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage>
    with TickerProviderStateMixin {
  final String phone = "50578496665";

  final AuthController _authController = AuthController();
  final CatalogoController _catalogoController = CatalogoController();

  late Future<List<Map<String, dynamic>>> _futureProductos;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _futureProductos = _catalogoController.listarProductosParaGrid();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _fadeController.forward();
  }

  Future<void> _recargarProductos() async {
    _fadeController.reset();

    setState(() {
      _futureProductos = _catalogoController.listarProductosParaGrid();
    });

    await _futureProductos;

    _fadeController.forward();
  }

  Future<void> _logout() async {
    await _authController.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthHomePage()),
      (route) => false,
    );
  }

  void _abrirCheckout() {
    showDialog(
      context: context,
      builder: (_) => CheckoutModal(phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _recargarProductos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 30),

                const Text(
                  'PROFESSIONAL COSMETICS',
                  style: TextStyle(
                    letterSpacing: 4,
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Catálogo Exclusivo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Descubre productos disponibles y realiza tus pedidos de forma rápida.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

                const SizedBox(height: 40),

                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureProductos,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(60),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final productos = snapshot.data!;

                    return ProductGrid(
                      productos: productos,
                      onProductTap: (producto) {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              ProductDetailModal(producto: producto),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 60),
                const FooterSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset('assets/img/Logo.png', height: 34),
          const SizedBox(width: 10),

          if (!isMobile) ...[
            _navItem('Home'),
            _navItem('About Us'),
            _navItem('Shop'),
            _navItem('Contact Us'),
          ],
        ],
      ),
      actions: [
        /// 🔄 actualizar
        IconButton(
          onPressed: _recargarProductos,
          icon: const Icon(Icons.refresh, color: Colors.black),
        ),

        /// 📋 formulario
        IconButton(
          onPressed: _abrirCheckout,
          icon: const Icon(Icons.assignment_outlined, color: Colors.black),
        ),

        /// 👤 usuario
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                'Hola, ${widget.userName}',
                style: const TextStyle(
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        /// 🛒 carrito con badge
        ListenableBuilder(
          listenable: CartController.instance,
          builder: (context, _) {
            final count = CartController.instance.totalItems;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const CartModal(),
                    );
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE91E63),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        /// 🚪 logout
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _navItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

///////////////////////////////////////////////////////////////
/// CHECKOUT MODAL
///////////////////////////////////////////////////////////////

class CheckoutModal extends StatefulWidget {
  final String phone;

  const CheckoutModal({super.key, required this.phone});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final referenciaCtrl = TextEditingController();
  final observacionesCtrl = TextEditingController();

  String metodoPago = "Efectivo";

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide =
        Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(_fade);

    _controller.forward();
  }

  void _confirmarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = CartController.instance.items;

    String productos = "";
    for (var item in cart) {
      productos += "- ${item.toString()}\n";
    }

    final msg = """
NUEVO PEDIDO

Nombre: ${nombreCtrl.text}
Teléfono: ${telefonoCtrl.text}
Dirección: ${direccionCtrl.text}
Referencia: ${referenciaCtrl.text}

Pago: $metodoPago

Pedido:
$productos

Observaciones:
${observacionesCtrl.text}
""";

    final url = Uri.parse(
        'https://wa.me/${widget.phone}?text=${Uri.encodeComponent(msg)}');

    await launchUrl(url, mode: LaunchMode.externalApplication);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance.items;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.all(30),
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset('assets/img/Logo.png', height: 60),

                    const SizedBox(height: 10),

                    const Text(
                      "Finalizar pedido",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    _input(nombreCtrl, "Nombre completo"),
                    _input(telefonoCtrl, "Teléfono"),
                    _input(direccionCtrl, "Dirección"),
                    _input(referenciaCtrl, "Referencia"),

                    DropdownButtonFormField<String>(
                      value: metodoPago,
                      items: ["Efectivo", "Transferencia"]
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => metodoPago = v!),
                      decoration: _decoration("Método de pago"),
                    ),

                    _input(observacionesCtrl, "Observaciones", maxLines: 3),

                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Resumen del pedido",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 10),

                    ...cart.map((item) => Text(item.toString())),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Regresar"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmarPedido,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                            ),
                            child: const Text("Confirmar pedido"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: _decoration(hint),
        validator: (v) => v!.isEmpty ? "Requerido" : null,
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F1F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}