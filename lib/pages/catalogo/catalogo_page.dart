import 'package:flutter/material.dart';

import '../../controllers/auth/auth_controller.dart';
import '../../controllers/catalogo/cart_controller.dart';
import '../../controllers/catalogo/catalogo_controller.dart';
import '../../controllers/catalogo/checkout_controller.dart';
import '../../models/catalogo/datos_cliente_model.dart';
import '../../models/catalogo/producto_catalogo_model.dart';
import '../auth/auth_page.dart';
import 'cart_page.dart';
import 'mood_palette.dart';

class CatalogoPage extends StatefulWidget {
  final String userName;

  const CatalogoPage({super.key, required this.userName});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final CatalogoController _catalogo = CatalogoController();
  final TextEditingController _buscarCtrl = TextEditingController();
  final AuthController _auth = AuthController();

  String _categoria = 'Todos';

  @override
  void initState() {
    super.initState();
    _catalogo.addListener(_sync);
    CartController.instance.addListener(_sync);
    _catalogo.cargarInicio();
    CartController.instance.cargarCarrito();
  }

  @override
  void dispose() {
    _catalogo.removeListener(_sync);
    CartController.instance.removeListener(_sync);
    _catalogo.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await Future.wait([
      _catalogo.cargarInicio(),
      CartController.instance.cargarCarrito(),
    ]);
  }

  Future<void> _logout() async {
    try {
      await _auth.logout();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthHomePage()),
      (_) => false,
    );
  }

  void _abrirCuenta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MyAccountSheet(userName: widget.userName, onLogout: _logout),
    );
  }

  void _abrirCarrito() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
  }

  void _abrirDetalle(ProductoCatalogo producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(producto: producto, onOpenCart: _abrirCarrito),
    );
  }

  Future<void> _buscar() async {
    await _catalogo.buscar(_buscarCtrl.text.trim());
    setState(() => _categoria = 'Todos');
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _catalogo.categorias;
    final grupos = _catalogo.productosPorCategoria(_categoria);

    return Scaffold(
      backgroundColor: MoodPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: MoodPalette.pink,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _MoodHeader(
                  userName: widget.userName,
                  searchController: _buscarCtrl,
                  categorias: categorias,
                  categoriaSeleccionada: _categoria,
                  onCategoria: (value) => setState(() => _categoria = value),
                  onSearch: _buscar,
                  onClear: () {
                    _buscarCtrl.clear();
                    _buscar();
                  },
                  onAccount: _abrirCuenta,
                  onCart: _abrirCarrito,
                ),
              ),
              if (_catalogo.loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: MoodPalette.pink)),
                )
              else if (_catalogo.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: _catalogo.error!, onRetry: _refresh),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _NovedadesCarousel(novedades: _catalogo.novedades),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Conoce nuestros productos',
                            style: TextStyle(
                              color: MoodPalette.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Actualizar'),
                          style: TextButton.styleFrom(foregroundColor: MoodPalette.pink),
                        ),
                      ],
                    ),
                  ),
                ),
                if (grupos.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No hay productos para mostrar.')),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate(
                      grupos.entries
                          .map(
                            (entry) => _CategorySection(
                              title: entry.key,
                              productos: entry.value,
                              onTap: _abrirDetalle,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodHeader extends StatelessWidget {
  final String userName;
  final TextEditingController searchController;
  final List<String> categorias;
  final String categoriaSeleccionada;
  final ValueChanged<String> onCategoria;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onAccount;
  final VoidCallback onCart;

  const _MoodHeader({
    required this.userName,
    required this.searchController,
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.onCategoria,
    required this.onSearch,
    required this.onClear,
    required this.onAccount,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: MoodPalette.mainGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Image.asset(
                  'assets/img/Logo.png',
                  errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: MoodPalette.pink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $userName', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    Text('Mood Professional', style: TextStyle(color: Colors.white.withOpacity(.78), fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _HeaderIcon(icon: Icons.person_rounded, onTap: onAccount),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: CartController.instance,
                builder: (_, __) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _HeaderIcon(icon: Icons.shopping_bag_rounded, onTap: onCart),
                    if (CartController.instance.totalItems > 0)
                      Positioned(
                        right: -2,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Text('${CartController.instance.totalItems}', style: const TextStyle(color: MoodPalette.pink, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Tu cabello, tu regla',
            style: TextStyle(color: Colors.white, fontSize: 29, height: 1.05, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text('Productos profesionales, novedades y pedidos desde la app.', style: TextStyle(color: Colors.white.withOpacity(.80), height: 1.4)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.16)]),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: MoodPalette.pink),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                    decoration: const InputDecoration(hintText: 'Buscar producto por nombre...', border: InputBorder.none),
                  ),
                ),
                IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: ElevatedButton(
                    onPressed: onSearch,
                    style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)), elevation: 0),
                    child: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categorias[index];
                final selected = cat == categoriaSeleccionada;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => onCategoria(cat),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(.18),
                  labelStyle: TextStyle(color: selected ? MoodPalette.pink : Colors.white, fontWeight: FontWeight.w800),
                  side: BorderSide(color: Colors.white.withOpacity(.25)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(.20))),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _NovedadesCarousel extends StatelessWidget {
  final List<dynamic> novedades;
  const _NovedadesCarousel({required this.novedades});

  @override
  Widget build(BuildContext context) {
    if (novedades.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
          child: Text('Novedades', style: TextStyle(color: MoodPalette.text, fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        SizedBox(
          height: 176,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: novedades.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final n = novedades[index];
              return Container(
                width: 295,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [MoodPalette.cardShadow(.08)]),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: n.imagenUrl.isEmpty
                          ? Container(color: MoodPalette.softPink)
                          : Image.network(n.imagenUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: MoodPalette.softPink)),
                    ),
                    Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(.65), Colors.black.withOpacity(.15)], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(n.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<ProductoCatalogo> productos;
  final ValueChanged<ProductoCatalogo> onTap;
  const _CategorySection({required this.title, required this.productos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(title, style: const TextStyle(color: MoodPalette.text, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          SizedBox(
            height: 292,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: productos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 13),
              itemBuilder: (_, index) => _ProductCard(producto: productos[index], onTap: () => onTap(productos[index])),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductoCatalogo producto;
  final VoidCallback onTap;
  const _ProductCard({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 178,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [MoodPalette.cardShadow(.07)], border: Border.all(color: MoodPalette.softPink)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: MoodPalette.softPink, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(producto.imagenPrincipal, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: MoodPalette.text)),
                  const SizedBox(height: 7),
                  Text('\$ ${producto.precioFinal.toStringAsFixed(2)}', style: const TextStyle(color: MoodPalette.pink, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailSheet extends StatefulWidget {
  final ProductoCatalogo producto;
  final VoidCallback onOpenCart;
  const _ProductDetailSheet({required this.producto, required this.onOpenCart});

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int cantidad = 1;
  int imgIndex = 0;
  bool saving = false;

  Future<void> _agregar() async {
    setState(() => saving = true);
    final img = widget.producto.imagenes.isNotEmpty ? widget.producto.imagenes[imgIndex] : null;
    final ok = await CartController.instance.agregarProducto(
      productoMasterId: widget.producto.idProducto,
      productoImagenId: img?['id'] is int ? img!['id'] : int.tryParse(img?['id']?.toString() ?? ''),
      cantidad: cantidad,
    );
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Producto agregado al carrito' : (CartController.instance.error ?? 'No se pudo agregar')), backgroundColor: ok ? Colors.green : Colors.redAccent));
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.producto.imagenes;
    final current = imgs.isNotEmpty ? (imgs[imgIndex]['imagen_url'] ?? '').toString() : widget.producto.imagenPrincipal;
    return DraggableScrollableSheet(
      initialChildSize: .88,
      minChildSize: .55,
      maxChildSize: .96,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: MoodPalette.background, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 52, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 18),
              Container(
                height: 310,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [MoodPalette.cardShadow(.07)]),
                child: Image.network(current, fit: BoxFit.contain, width: double.infinity, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 60)),
              ),
              if (imgs.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  children: List.generate(imgs.length, (index) {
                    final url = (imgs[index]['imagen_url'] ?? '').toString();
                    final selected = index == imgIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => imgIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 74,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? MoodPalette.pink : Colors.grey.shade200, width: selected ? 2 : 1), color: Colors.white),
                          child: Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 20),
              Text(widget.producto.nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: MoodPalette.text)),
              const SizedBox(height: 8),
              Text(widget.producto.descripcion, style: const TextStyle(color: MoodPalette.muted, height: 1.45)),
              const SizedBox(height: 14),
              Text('\$ ${widget.producto.precioFinal.toStringAsFixed(2)}', style: const TextStyle(color: MoodPalette.pink, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(onPressed: cantidad > 1 ? () => setState(() => cantidad--) : null, icon: const Icon(Icons.remove_circle_outline)),
                  Text('$cantidad', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  IconButton(onPressed: () => setState(() => cantidad++), icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : _agregar,
                  icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shopping_bag_rounded),
                  label: const Text('Agregar al carrito'),
                  style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyAccountSheet extends StatefulWidget {
  final String userName;
  final VoidCallback onLogout;
  const _MyAccountSheet({required this.userName, required this.onLogout});

  @override
  State<_MyAccountSheet> createState() => _MyAccountSheetState();
}

class _MyAccountSheetState extends State<_MyAccountSheet> {
  final CheckoutController controller = CheckoutController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_sync);
    controller.inicializar();
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
    return Container(
      decoration: const BoxDecoration(color: MoodPalette.background, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 24),
      child: controller.loading
          ? const SizedBox(height: 320, child: Center(child: CircularProgressIndicator(color: MoodPalette.pink)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, color: MoodPalette.pink),
                      const SizedBox(width: 8),
                      Expanded(child: Text('My Account - ${widget.userName}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CustomerForm(
                    initial: controller.datosCliente,
                    departamentos: controller.departamentos,
                    onSubmit: (datos) async {
                      final ok = await controller.guardarDatos(datos);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Datos guardados correctamente' : controller.error ?? 'Error'), backgroundColor: ok ? Colors.green : Colors.redAccent));
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: widget.onLogout, icon: const Icon(Icons.logout_rounded), label: const Text('Cerrar sesión')),
                ],
              ),
            ),
    );
  }
}

class _CustomerForm extends StatefulWidget {
  final DatosClienteModel? initial;
  final List<dynamic> departamentos;
  final Future<void> Function(DatosClienteModel datos) onSubmit;
  const _CustomerForm({this.initial, required this.departamentos, required this.onSubmit});

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nombres;
  late final TextEditingController apellidos;
  late final TextEditingController telefono;
  late final TextEditingController direccion;
  late final TextEditingController referencia;
  int? departamentoId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nombres = TextEditingController(text: widget.initial?.nombres ?? '');
    apellidos = TextEditingController(text: widget.initial?.apellidos ?? '');
    telefono = TextEditingController(text: widget.initial?.telefono ?? '');
    direccion = TextEditingController(text: widget.initial?.direccion ?? '');
    referencia = TextEditingController(text: widget.initial?.referencia ?? '');
    departamentoId = widget.initial?.departamentoId;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);
    await widget.onSubmit(DatosClienteModel(nombres: nombres.text.trim(), apellidos: apellidos.text.trim(), telefono: telefono.text.trim(), direccion: direccion.text.trim(), referencia: referencia.text.trim(), departamentoId: departamentoId));
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _field(nombres, 'Nombres', Icons.person_outline, required: true),
          _field(apellidos, 'Apellidos', Icons.badge_outlined),
          _field(telefono, 'Teléfono', Icons.phone_outlined, required: true, keyboard: TextInputType.phone),
          DropdownButtonFormField<int>(
            value: departamentoId,
            decoration: _decoration('Departamento / zona', Icons.location_city_outlined),
            items: widget.departamentos.map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.nombre))).toList(),
            onChanged: (value) => setState(() => departamentoId = value),
          ),
          _field(direccion, 'Dirección', Icons.home_outlined, required: true),
          _field(referencia, 'Referencia', Icons.notes_outlined),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded),
              label: Text(saving ? 'Guardando...' : 'Guardar datos'),
              style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ],
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
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 70),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
