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
import 'pedidos_page.dart';
import 'widgets/web_safe_network_image.dart';

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
      _catalogo.cargarInicio(forceRefresh: true),
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
      builder: (_) => _MyAccountSheet(
        userName: widget.userName,
        onLogout: _logout,
      ),
    );
  }

  void _abrirCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  void _abrirPedidos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PedidosPage()),
    );
  }

  void _abrirDetalle(ProductoCatalogo producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        producto: producto,
        onOpenCart: _abrirCarrito,
      ),
    );
  }

  Future<void> _buscar() async {
    await _catalogo.buscar(_buscarCtrl.text.trim());
    if (mounted) setState(() => _categoria = 'Todos');
  }

  List<Widget> _buildCategorySlivers(
    Map<String, List<ProductoCatalogo>> grupos,
  ) {
    return grupos.entries.expand<Widget>((entry) {
      return [
        SliverToBoxAdapter(
          child: _ResponsiveShell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: _CategoryTitleHeader(
                title: entry.key,
                total: entry.value.length,
              ),
            ),
          ),
        ),
        _ProductSliverGrid(
          productos: entry.value,
          onTap: _abrirDetalle,
        ),
      ];
    }).toList(growable: false);
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
            cacheExtent: 120,
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
                  onPedidos: _abrirPedidos,
                  onCart: _abrirCarrito,
                ),
              ),
              if (_catalogo.loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: MoodPalette.pink,
                    ),
                  ),
                )
              else if (_catalogo.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: _catalogo.error!,
                    onRetry: _refresh,
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _NovedadesCarousel(
                    novedades: _catalogo.novedades,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ResponsiveShell(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                      child: _CatalogSectionHeader(onRefresh: _refresh),
                    ),
                  ),
                ),
                if (grupos.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('No hay productos para mostrar.'),
                    ),
                  )
                else
                  ..._buildCategorySlivers(grupos),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const _ResponsiveShell({
    required this.child,
    this.maxWidth = 1220,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _CatalogSectionHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _CatalogSectionHeader({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conoce nuestros productos',
          style: TextStyle(
            color: MoodPalette.text,
            fontSize: isWide ? 30 : 24,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Catálogo visual, cards amplias y compra rápida en cualquier pantalla.',
          style: TextStyle(
            color: MoodPalette.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );

    final refreshButton = TextButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Actualizar'),
      style: TextButton.styleFrom(
        foregroundColor: MoodPalette.pink,
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow(),
          const SizedBox(height: 12),
          titleBlock,
          const SizedBox(height: 10),
          refreshButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SectionEyebrow(),
        const SizedBox(width: 20),
        Expanded(child: titleBlock),
        const SizedBox(width: 14),
        refreshButton,
      ],
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MoodPalette.softPink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: MoodPalette.pink.withValues(alpha: .12),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: MoodPalette.pink,
            size: 17,
          ),
          SizedBox(width: 7),
          Text(
            'Marketplace Mood',
            style: TextStyle(
              color: MoodPalette.pink,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
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
  final VoidCallback onPedidos;
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
    required this.onPedidos,
    required this.onCart,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Container(
      decoration: const BoxDecoration(
        gradient: MoodPalette.mainGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -80,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -90,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          _ResponsiveShell(
            padding: EdgeInsets.fromLTRB(
              isWide ? 24 : 16,
              14,
              isWide ? 24 : 16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: isWide ? 54 : 46,
                      height: isWide ? 54 : 46,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [MoodPalette.cardShadow(.18)],
                      ),
                      child: Image.asset(
                        'assets/img/Logo.png',
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          color: MoodPalette.pink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $userName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Mood Professional',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .78),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWide) ...[
                      const _HeaderNavChip(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Catálogo',
                      ),
                      const SizedBox(width: 8),
                      const _HeaderNavChip(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Novedades',
                      ),
                      const SizedBox(width: 12),
                    ],
                    _HeaderIcon(
                      icon: Icons.person_rounded,
                      onTap: onAccount,
                    ),
                    const SizedBox(width: 8),
                    _PedidosHeaderButton(onTap: onPedidos),
                    const SizedBox(width: 8),
                    ListenableBuilder(
                      listenable: CartController.instance,
                      builder: (_, __) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _HeaderIcon(
                            icon: Icons.shopping_bag_rounded,
                            onTap: onCart,
                          ),
                          if (CartController.instance.totalItems > 0)
                            Positioned(
                              right: -2,
                              top: -3,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${CartController.instance.totalItems}',
                                  style: const TextStyle(
                                    color: MoodPalette.pink,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isWide ? 30 : 22),
                Builder(
                  builder: (context) {
                    final heroCopy = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Catálogo multiplataforma',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tu cabello,\ntu regla',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWide ? 52 : 34,
                            height: .98,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Productos profesionales, novedades flotantes y pedidos fluidos desde iOS, Web, móvil y escritorio.',
                          maxLines: isWide ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .82),
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );

                    if (!isWide) return heroCopy;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 6, child: heroCopy),
                        const SizedBox(width: 28),
                        const Expanded(
                          flex: 5,
                          child: _StorePreviewStack(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _SearchPanel(
                  searchController: searchController,
                  categorias: categorias,
                  categoriaSeleccionada: categoriaSeleccionada,
                  onCategoria: onCategoria,
                  onSearch: onSearch,
                  onClear: onClear,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> categorias;
  final String categoriaSeleccionada;
  final ValueChanged<String> onCategoria;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _SearchPanel({
    required this.searchController,
    required this.categorias,
    required this.categoriaSeleccionada,
    required this.onCategoria,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Container(
      padding: EdgeInsets.all(isWide ? 12 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [MoodPalette.cardShadow(.18)],
        border: Border.all(color: Colors.white.withValues(alpha: .42)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.search_rounded, color: MoodPalette.pink),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: const InputDecoration(
                    hintText: 'Buscar producto por nombre...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
              Container(
                margin: const EdgeInsets.only(right: 3),
                child: ElevatedButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: isWide ? const Text('Buscar') : const SizedBox.shrink(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MoodPalette.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 18 : 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (categorias.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                    selectedColor: MoodPalette.pink,
                    backgroundColor: MoodPalette.softPink,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : MoodPalette.pink,
                      fontWeight: FontWeight.w900,
                    ),
                    side: BorderSide(
                      color: selected
                          ? MoodPalette.pink
                          : MoodPalette.pink.withValues(alpha: .12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderNavChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderNavChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
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

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .20)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _PedidosHeaderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PedidosHeaderButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Mis pedidos',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: .20)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 19,
              ),
              SizedBox(width: 6),
              Text(
                'Pedidos',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorePreviewStack extends StatelessWidget {
  const _StorePreviewStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 238,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 24,
            child: _MiniStorePanel(
              width: 148,
              height: 170,
              title: 'OFERTAS',
              subtitle: 'Hasta 12%',
              icon: Icons.percent_rounded,
              angle: .035,
              colors: const [Color(0xFFFFF1F7), Color(0xFFFFCFE2)],
            ),
          ),
          Positioned(
            left: 0,
            top: 36,
            child: _MiniStorePanel(
              width: 150,
              height: 160,
              title: 'LOOKBOOK',
              subtitle: 'Estilos',
              icon: Icons.auto_awesome_rounded,
              angle: -.035,
              colors: const [Color(0xFFEDE7FF), Color(0xFFFFE0EF)],
            ),
          ),
          Positioned(
            left: 62,
            right: 42,
            top: 0,
            bottom: 0,
            child: _MainStorePanel(),
          ),
        ],
      ),
    );
  }
}

class _MiniStorePanel extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final String subtitle;
  final IconData icon;
  final double angle;
  final List<Color> colors;

  const _MiniStorePanel({
    required this.width,
    required this.height,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.angle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [MoodPalette.cardShadow(.22)],
          border: Border.all(color: Colors.white.withValues(alpha: .6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: MoodPalette.pink, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: MoodPalette.text,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: MoodPalette.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainStorePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [MoodPalette.cardShadow(.24)],
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: MoodPalette.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: MoodPalette.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: MoodPalette.hotPink.withValues(alpha: .5),
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 72,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFEEF7), Color(0xFFF4E8FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 12,
                    child: Icon(
                      Icons.spa_rounded,
                      color: MoodPalette.pink.withValues(alpha: .25),
                      size: 118,
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 74,
                          height: 8,
                          decoration: BoxDecoration(
                            color: MoodPalette.pink.withValues(alpha: .28),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'YA ES\nTEMPORADA',
                          style: TextStyle(
                            color: MoodPalette.text,
                            height: .92,
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: MoodPalette.pink,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Ver novedades',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovedadesCarousel extends StatefulWidget {
  final List<dynamic> novedades;

  const _NovedadesCarousel({
    required this.novedades,
  });

  @override
  State<_NovedadesCarousel> createState() => _NovedadesCarouselState();
}

class _NovedadesCarouselState extends State<_NovedadesCarousel> {
  late PageController _controller;
  double _viewportFraction = .86;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final next = _resolveViewportFraction(MediaQuery.sizeOf(context).width);
    if ((next - _viewportFraction).abs() < .001) return;

    final currentPage = _controller.hasClients
        ? (_controller.page?.round() ?? _controller.initialPage)
        : _controller.initialPage;

    _controller.dispose();
    _viewportFraction = next;
    _controller = PageController(
      viewportFraction: _viewportFraction,
      initialPage: widget.novedades.isEmpty
          ? 0
          : currentPage.clamp(0, widget.novedades.length - 1).toInt(),
    );
  }

  double _resolveViewportFraction(double width) {
    if (width >= 1000) return .46;
    if (width >= 620) return .62;
    return .86;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.novedades.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final height = isWide ? 330.0 : 244.0;

    return _ResponsiveShell(
      maxWidth: 1260,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isWide ? 18 : 0,
          24,
          isWide ? 18 : 0,
          4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 18),
              child: Row(
                children: [
                  const _SectionEyebrow(),
                  const SizedBox(width: 12),
                  Text(
                    'Novedades flotantes',
                    style: TextStyle(
                      color: MoodPalette.text,
                      fontSize: isWide ? 26 : 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                padEnds: true,
                itemCount: widget.novedades.length,
                itemBuilder: (context, index) {
                  final n = widget.novedades[index];

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double page = 0;

                      if (_controller.hasClients &&
                          _controller.position.hasContentDimensions) {
                        page = _controller.page ??
                            _controller.initialPage.toDouble();
                      }

                      final distance = (page - index).abs().clamp(0.0, 1.0);
                      final scale = 1 - (distance * .055);
                      final lift = 20 * distance;

                      return Transform.translate(
                        offset: Offset(0, lift),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: _FloatingNoveltyCard(
                      novedad: n,
                      index: index,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNoveltyCard extends StatelessWidget {
  final dynamic novedad;
  final int index;

  const _FloatingNoveltyCard({
    required this.novedad,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final image = (novedad.imagenUrl ?? '').toString();
    final title = (novedad.titulo ?? 'Novedad').toString();
    final desc = (novedad.descripcion ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 34,
              offset: const Offset(0, 22),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: .75)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: image.isEmpty
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MoodPalette.softPink,
                            MoodPalette.softPurple,
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: MoodPalette.pink,
                        size: 72,
                      ),
                    )
                  : WebSafeNetworkImage(
                      url: image,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: MoodPalette.softPink,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: MoodPalette.pink,
                          size: 54,
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: .76),
                      Colors.black.withValues(alpha: .28),
                      Colors.black.withValues(alpha: .10),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: MoodPalette.pink,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Novedad ${index + 1}',
                      style: const TextStyle(
                        color: MoodPalette.pink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 25,
                      height: 1.02,
                    ),
                  ),
                  if (desc.trim().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .86),
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTitleHeader extends StatelessWidget {
  final String title;
  final int total;

  const _CategoryTitleHeader({
    required this.title,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: MoodPalette.text,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [MoodPalette.cardShadow(.05)],
          ),
          child: Text(
            '$total productos',
            style: const TextStyle(
              color: MoodPalette.muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductSliverGrid extends StatelessWidget {
  final List<ProductoCatalogo> productos;
  final ValueChanged<ProductoCatalogo> onTap;

  const _ProductSliverGrid({
    required this.productos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const maxWidth = 1220.0;
        final viewportWidth = constraints.crossAxisExtent;
        final horizontalPadding = viewportWidth > maxWidth
            ? ((viewportWidth - maxWidth) / 2) + 18
            : 18.0;
        final gridWidth = viewportWidth - (horizontalPadding * 2);

        final count = gridWidth >= 1120
            ? 4
            : (gridWidth >= 820 ? 3 : (gridWidth >= 560 ? 2 : 1));

        final ratio = gridWidth >= 1120
            ? .76
            : (gridWidth >= 820 ? .74 : (gridWidth >= 560 ? .72 : .82));

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            28,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: ratio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final producto = productos[index];

                return RepaintBoundary(
                  child: _ProductCard(
                    key: ValueKey('producto_${producto.idProducto}'),
                    producto: producto,
                    onTap: () => onTap(producto),
                  ),
                );
              },
              childCount: productos.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductoCatalogo producto;
  final VoidCallback onTap;

  const _ProductCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hover = false;
  bool _saving = false;

  Future<void> _quickAdd() async {
    if (_saving) return;

    setState(() => _saving = true);

    final img = widget.producto.imagenes.isNotEmpty
        ? widget.producto.imagenes.first
        : null;

    final ok = await CartController.instance.agregarProducto(
      productoMasterId: widget.producto.idProducto,
      productoImagenId: _imagenIdFrom(img),
      cantidad: 1,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${widget.producto.nombre} agregado al carrito'
              : (CartController.instance.error ?? 'No se pudo agregar'),
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int? _imagenIdFrom(dynamic image) {
    if (image == null) return null;
    if (image is Map<String, dynamic>) return _intOrNull(image['id']);
    if (image is Map) return _intOrNull(image['id']);
    return null;
  }

  int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _hover = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hover = false);
      },
      child: AnimatedScale(
        scale: _hover ? 1.012 : 1,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _hover
                      ? MoodPalette.pink.withValues(alpha: .22)
                      : MoodPalette.softPink,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: _hover ? .13 : .07,
                    ),
                    blurRadius: _hover ? 28 : 18,
                    offset: Offset(0, _hover ? 14 : 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 63,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFFF7FB),
                                  Color(0xFFF6EEFF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: WebSafeNetworkImage(
                                url: widget.producto.imagenPrincipal,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorWidget: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: MoodPalette.pink,
                                  size: 54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: MoodPalette.pink,
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Pro',
                                  style: TextStyle(
                                    color: MoodPalette.pink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: IconButton.filled(
                            onPressed: _saving ? null : _quickAdd,
                            style: IconButton.styleFrom(
                              backgroundColor: MoodPalette.pink,
                              foregroundColor: Colors.white,
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 37,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.producto.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: MoodPalette.text,
                              fontSize: 17,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Expanded(
                            child: Text(
                              widget.producto.descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: MoodPalette.muted,
                                height: 1.32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '\$ ${widget.producto.precioFinal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: MoodPalette.pink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const Text(
                                'Ver detalle',
                                style: TextStyle(
                                  color: MoodPalette.muted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: MoodPalette.pink,
                                size: 17,
                              ),
                            ],
                          ),
                        ],
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
}

class _ProductDetailSheet extends StatefulWidget {
  final ProductoCatalogo producto;
  final VoidCallback onOpenCart;

  const _ProductDetailSheet({
    required this.producto,
    required this.onOpenCart,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  int cantidad = 1;
  int imgIndex = 0;
  bool saving = false;

  Future<void> _agregar() async {
    setState(() => saving = true);

    final img = widget.producto.imagenes.isNotEmpty
        ? widget.producto.imagenes[imgIndex]
        : null;

    final ok = await CartController.instance.agregarProducto(
      productoMasterId: widget.producto.idProducto,
      productoImagenId: _imagenIdFrom(img),
      cantidad: cantidad,
    );

    if (!mounted) return;

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Producto agregado al carrito'
              : (CartController.instance.error ?? 'No se pudo agregar'),
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (ok) Navigator.pop(context);
  }

  int? _imagenIdFrom(dynamic image) {
    if (image == null) return null;
    if (image is Map<String, dynamic>) return _intOrNull(image['id']);
    if (image is Map) return _intOrNull(image['id']);
    return null;
  }

  int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _imageUrlFrom(dynamic image) {
    if (image is Map<String, dynamic>) {
      return (image['imagen_url'] ?? '').toString();
    }

    if (image is Map) {
      return (image['imagen_url'] ?? '').toString();
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.producto.imagenes;
    final current = imgs.isNotEmpty
        ? _imageUrlFrom(imgs[imgIndex])
        : widget.producto.imagenPrincipal;

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 860;

    return DraggableScrollableSheet(
      initialChildSize: .92,
      minChildSize: .55,
      maxChildSize: .97,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: MoodPalette.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: SingleChildScrollView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 18,
                16,
                isWide ? 24 : 18,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (context) {
                      final gallery = _DetailGallery(
                        current: current,
                        images: imgs,
                        imgIndex: imgIndex,
                        onImage: (index) => setState(() => imgIndex = index),
                        isWide: isWide,
                      );

                      final info = _DetailInfo(
                        producto: widget.producto,
                        cantidad: cantidad,
                        saving: saving,
                        onMinus: cantidad > 1
                            ? () => setState(() => cantidad--)
                            : null,
                        onPlus: () => setState(() => cantidad++),
                        onAdd: _agregar,
                        onOpenCart: widget.onOpenCart,
                      );

                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            gallery,
                            const SizedBox(height: 22),
                            info,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: gallery),
                          const SizedBox(width: 28),
                          Expanded(flex: 5, child: info),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailGallery extends StatelessWidget {
  final String current;
  final List<dynamic> images;
  final int imgIndex;
  final ValueChanged<int> onImage;
  final bool isWide;

  const _DetailGallery({
    required this.current,
    required this.images,
    required this.imgIndex,
    required this.onImage,
    required this.isWide,
  });

  String _imageUrlFrom(dynamic image) {
    if (image is Map<String, dynamic>) {
      return (image['imagen_url'] ?? '').toString();
    }

    if (image is Map) {
      return (image['imagen_url'] ?? '').toString();
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: isWide ? 500 : 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [MoodPalette.cardShadow(.09)],
            border: Border.all(color: MoodPalette.softPink),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF7FB), Color(0xFFF6EEFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWide ? 30 : 18),
                    child: WebSafeNetworkImage(
                      url: current,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorWidget: const Icon(
                        Icons.image_outlined,
                        color: MoodPalette.pink,
                        size: 70,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .94),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: MoodPalette.pink,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Vista grande',
                        style: TextStyle(
                          color: MoodPalette.pink,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final url = _imageUrlFrom(images[index]);
                final selected = index == imgIndex;

                return GestureDetector(
                  onTap: () => onImage(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 86,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? MoodPalette.pink
                            : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                      color: Colors.white,
                      boxShadow: selected ? [MoodPalette.cardShadow(.08)] : null,
                    ),
                    child: WebSafeNetworkImage(
                      url: url,
                      fit: BoxFit.contain,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailInfo extends StatelessWidget {
  final ProductoCatalogo producto;
  final int cantidad;
  final bool saving;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;
  final VoidCallback onOpenCart;

  const _DetailInfo({
    required this.producto,
    required this.cantidad,
    required this.saving,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
    required this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [MoodPalette.cardShadow(.07)],
        border: Border.all(color: MoodPalette.softPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionEyebrow(),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            producto.nombre,
            style: const TextStyle(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: MoodPalette.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            producto.descripcion,
            style: const TextStyle(
              color: MoodPalette.muted,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '\$ ${producto.precioFinal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: MoodPalette.pink,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MoodPalette.softPink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Text(
                  'Cantidad',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: MoodPalette.text,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onMinus,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '$cantidad',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed: onPlus,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onAdd,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_bag_rounded),
              label: Text(saving ? 'Agregando...' : 'Agregar al carrito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MoodPalette.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onOpenCart();
              },
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: const Text('Ir al carrito'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MoodPalette.pink,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyAccountSheet extends StatefulWidget {
  final String userName;
  final VoidCallback onLogout;

  const _MyAccountSheet({
    required this.userName,
    required this.onLogout,
  });

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
      decoration: const BoxDecoration(
        color: MoodPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: controller.loading
          ? const SizedBox(
              height: 320,
              child: Center(
                child: CircularProgressIndicator(color: MoodPalette.pink),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: MoodPalette.pink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'My Account - ${widget.userName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CustomerForm(
                    initial: controller.datosCliente,
                    departamentos: controller.departamentos,
                    onSubmit: (datos) async {
                      final ok = await controller.guardarDatos(datos);
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Datos guardados correctamente'
                                : controller.error ?? 'Error',
                          ),
                          backgroundColor:
                              ok ? Colors.green : Colors.redAccent,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                  ),
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

  const _CustomerForm({
    this.initial,
    required this.departamentos,
    required this.onSubmit,
  });

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

    await widget.onSubmit(
      DatosClienteModel(
        nombres: nombres.text.trim(),
        apellidos: apellidos.text.trim(),
        telefono: telefono.text.trim(),
        direccion: direccion.text.trim(),
        referencia: referencia.text.trim(),
        departamentoId: departamentoId,
      ),
    );

    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _field(
            nombres,
            'Nombres',
            Icons.person_outline,
            required: true,
          ),
          _field(
            apellidos,
            'Apellidos',
            Icons.badge_outlined,
          ),
          _field(
            telefono,
            'Teléfono',
            Icons.phone_outlined,
            required: true,
            keyboard: TextInputType.phone,
          ),
          DropdownButtonFormField<int>(
            value: departamentoId,
            decoration: _decoration(
              'Departamento / zona',
              Icons.location_city_outlined,
            ),
            items: widget.departamentos
                .map(
                  (d) => DropdownMenuItem<int>(
                    value: d.id,
                    child: Text(d.nombre),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => departamentoId = value),
          ),
          _field(
            direccion,
            'Dirección',
            Icons.home_outlined,
            required: true,
          ),
          _field(
            referencia,
            'Referencia',
            Icons.notes_outlined,
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
              label: Text(saving ? 'Guardando...' : 'Guardar datos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MoodPalette.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null
            : null,
        decoration: _decoration(label, icon),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 70,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
