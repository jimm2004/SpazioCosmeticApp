import 'package:flutter/material.dart';

import '../../../controllers/catalogo/cart_controller.dart';
import '../cart_page.dart';
import 'web_safe_network_image.dart';

class ProductDiscoveryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> productos;
  final Future<void> Function()? onCartChanged;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const ProductDiscoveryGrid({
    super.key,
    required this.productos,
    this.onCartChanged,
    this.controller,
    this.physics,
    this.shrinkWrap = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        child: Center(
          child: Text(
            'No hay productos para mostrar con este filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1220),
        child: Padding(
          padding: padding.add(
            EdgeInsets.symmetric(horizontal: screenWidth < 700 ? 16 : 28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final count = width >= 1280
                  ? 4
                  : width >= 920
                      ? 3
                      : width >= 600
                          ? 2
                          : 1;

              final ratio = width >= 1280
                  ? .76
                  : width >= 920
                      ? .74
                      : width >= 600
                          ? .72
                          : .82;

              return GridView.builder(
                controller: controller,
                shrinkWrap: shrinkWrap,
                physics: physics ?? const NeverScrollableScrollPhysics(),
                cacheExtent: 240,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: productos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (context, index) {
                  final card = RepaintBoundary(
                    child: ProductShowcaseCard(
                      key: ValueKey(ProductUiHelper.productKey(productos[index])),
                      producto: productos[index],
                      onCartChanged: onCartChanged,
                    ),
                  );

                  if (index > 15) return card;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 160 + (index * 18)),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: card,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProductShowcaseCard extends StatefulWidget {
  final Map<String, dynamic> producto;
  final Future<void> Function()? onCartChanged;

  const ProductShowcaseCard({
    super.key,
    required this.producto,
    this.onCartChanged,
  });

  @override
  State<ProductShowcaseCard> createState() => _ProductShowcaseCardState();
}

class _ProductShowcaseCardState extends State<ProductShowcaseCard> {
  bool _hover = false;
  bool _adding = false;

  Future<void> _addPrincipal() async {
    if (_adding) return;

    final imagen = ProductUiHelper.principalImage(widget.producto);
    final payload = ProductUiHelper.productForCart(
      widget.producto,
      selectedImage: imagen,
    );

    final productoMasterId = ProductUiHelper.toNullableInt(
          payload['producto_master_id'] ?? payload['id_producto'] ?? payload['id'],
        ) ??
        0;

    if (productoMasterId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el ID del producto.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final stockDisponible = ProductUiHelper.stock(widget.producto);
    if (!ProductUiHelper.hasStockFlag(widget.producto) || stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto está agotado.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _adding = true);

    final ok = await CartController.instance.agregarProducto(
      productoMasterId: productoMasterId,
      productoImagenId: ProductUiHelper.toNullableInt(
        payload['producto_imagen_id'] ?? payload['imagen_id'],
      ),
      cantidad: 1,
    );

    if (!mounted) return;
    setState(() => _adding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${ProductUiHelper.name(widget.producto)} agregado al carrito'
              : (CartController.instance.error ?? 'No se pudo agregar al carrito'),
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    await widget.onCartChanged?.call();
  }

  void _openDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        producto: widget.producto,
        onCartChanged: widget.onCartChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagen = ProductUiHelper.principalImage(widget.producto);
    final nombre = ProductUiHelper.name(widget.producto);
    final descripcion = ProductUiHelper.description(widget.producto);
    final categoria = ProductUiHelper.category(widget.producto);
    final precio = ProductUiHelper.priceText(widget.producto);
    final stock = ProductUiHelper.stock(widget.producto);
    final hasStock = stock > 0 || ProductUiHelper.hasStockFlag(widget.producto);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.01 : 1,
        duration: const Duration(milliseconds: 160),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openDetail,
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _hover ? const Color(0xFFE91E63).withValues(alpha: .25) : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hover ? .11 : .05),
                    blurRadius: _hover ? 22 : 10,
                    offset: Offset(0, _hover ? 10 : 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 66,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFFFDFBFC),
                            child: imagen == null
                                ? const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 56,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: WebSafeNetworkImage(
                                      url: imagen.url,
                                      fit: BoxFit.contain,
                                      errorWidget: const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey,
                                        size: 48,
                                      ),
                                      loadingWidget: const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFE91E63),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria.isEmpty ? 'Producto' : categoria,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: IconButton.filled(
                            onPressed: _adding || !hasStock ? null : _addPrincipal,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            icon: _adding
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 34,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              if (hasStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Stock',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Expanded(
                            child: Text(
                              descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54, height: 1.35),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  precio,
                                  style: const TextStyle(
                                    color: Color(0xFFE91E63),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Text(
                                'Ver',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFE91E63), size: 17),
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

class ProductDetailSheet extends StatefulWidget {
  final Map<String, dynamic> producto;
  final int initialIndex;
  final Future<void> Function()? onCartChanged;

  const ProductDetailSheet({
    super.key,
    required this.producto,
    this.initialIndex = 0,
    this.onCartChanged,
  });

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  late final PageController _controller;
  late int _selected;
  int _cantidad = 1;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    final images = ProductUiHelper.images(widget.producto, limit: 2);
    _selected = images.isEmpty ? 0 : widget.initialIndex.clamp(0, images.length - 1).toInt();
    _controller = PageController(initialPage: _selected);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add({bool openCart = false}) async {
    if (_adding) return;

    final images = ProductUiHelper.images(widget.producto, limit: 2);
    final selectedImage = images.isEmpty ? null : images[_selected.clamp(0, images.length - 1).toInt()];
    final payload = ProductUiHelper.productForCart(widget.producto, selectedImage: selectedImage);
    final productoMasterId = ProductUiHelper.toNullableInt(
          payload['producto_master_id'] ?? payload['id_producto'] ?? payload['id'],
        ) ??
        0;

    if (productoMasterId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el ID del producto.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final stockDisponible = ProductUiHelper.stock(widget.producto);
    if (!ProductUiHelper.hasStockFlag(widget.producto) || stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este producto está agotado.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_cantidad > stockDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo hay $stockDisponible unidades disponibles.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _adding = true);

    final ok = await CartController.instance.agregarProducto(
      productoMasterId: productoMasterId,
      productoImagenId: ProductUiHelper.toNullableInt(
        payload['producto_imagen_id'] ?? payload['imagen_id'],
      ),
      cantidad: _cantidad,
    );

    if (!mounted) return;
    setState(() => _adding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${ProductUiHelper.name(widget.producto)} agregado al carrito'
              : (CartController.instance.error ?? 'No se pudo agregar al carrito'),
        ),
        backgroundColor: ok ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (!ok) return;
    await widget.onCartChanged?.call();

    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();

    if (openCart) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const CartPage()),
      );
    }
  }

  void _openImageViewer(int index) {
    final urls = ProductUiHelper.images(widget.producto, limit: 2)
        .map((img) => img.url)
        .where((url) => url.trim().isNotEmpty)
        .toList();

    if (urls.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.92),
      builder: (_) => _FullscreenProductImageCarousel(
        urls: urls,
        initialIndex: index.clamp(0, urls.length - 1).toInt(),
        title: ProductUiHelper.name(widget.producto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = ProductUiHelper.images(widget.producto, limit: 2);
    final nombre = ProductUiHelper.name(widget.producto);
    final descripcion = ProductUiHelper.description(widget.producto);
    final precio = ProductUiHelper.priceText(widget.producto);
    final categoria = ProductUiHelper.category(widget.producto);
    final stockDisponible = ProductUiHelper.stock(widget.producto);

    return DraggableScrollableSheet(
      initialChildSize: .92,
      minChildSize: .62,
      maxChildSize: .97,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoria.isEmpty ? 'Producto destacado' : categoria,
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: MediaQuery.sizeOf(context).width < 680 ? 390 : 500,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBFC),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: images.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                        )
                      : PageView.builder(
                          controller: _controller,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _selected = i),
                          itemBuilder: (_, i) {
                            return GestureDetector(
                              onTap: () => _openImageViewer(i),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: WebSafeNetworkImage(
                                  url: images[i].url,
                                  fit: BoxFit.contain,
                                  errorWidget: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 58,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toca la imagen para verla grande. Puedes deslizar entre las 2 fotos.',
                  style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                if (images.length > 1) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final selected = i == _selected;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selected = i);
                            _controller.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 92,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? const Color(0xFFE91E63) : Colors.grey.shade300,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: WebSafeNetworkImage(
                              url: images[i].url,
                              fit: BoxFit.contain,
                              errorWidget: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  descripcion,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  precio,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: stockDisponible > 0 ? Colors.green.withOpacity(.10) : Colors.redAccent.withOpacity(.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    stockDisponible > 0 ? 'Stock disponible: $stockDisponible' : 'Producto agotado',
                    style: TextStyle(
                      color: stockDisponible > 0 ? Colors.green.shade700 : Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBFC),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_cantidad',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        onPressed: _cantidad < stockDisponible ? () => setState(() => _cantidad++) : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _adding || stockDisponible <= 0 ? null : () => _add(),
                        icon: _adding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: Text(_adding ? 'Agregando...' : 'Agregar al carrito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _adding || stockDisponible <= 0 ? null : () => _add(openCart: true),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Carrito'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _FullscreenProductImageCarousel extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final String title;

  const _FullscreenProductImageCarousel({
    required this.urls,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_FullscreenProductImageCarousel> createState() => _FullscreenProductImageCarouselState();
}

class _FullscreenProductImageCarouselState extends State<_FullscreenProductImageCarousel> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index < 0 || index >= widget.urls.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox.expand(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: WebSafeNetworkImage(
                        url: widget.urls[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        loadOnlyWhenVisible: false,
                        deferWhileScrolling: false,
                        errorWidget: const Icon(Icons.image_not_supported_outlined, color: Colors.white70, size: 70),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(.14)),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '${_index + 1}/${widget.urls.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.urls.length > 1) ...[
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(.12)),
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(.12)),
                    onPressed: _index < widget.urls.length - 1 ? () => _go(_index + 1) : null,
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: Center(
                  child: SizedBox(
                    height: 76,
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.urls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final selected = index == _index;
                        return GestureDetector(
                          onTap: () => _go(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 76,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: selected ? const Color(0xFFE91E63) : Colors.white, width: selected ? 3 : 1),
                            ),
                            child: WebSafeNetworkImage(
                              url: widget.urls[index],
                              fit: BoxFit.contain,
                              loadOnlyWhenVisible: false,
                              deferWhileScrolling: false,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductImageData {
  final int? id;
  final String url;

  const ProductImageData({
    required this.id,
    required this.url,
  });
}

class ProductUiHelper {
  static String productKey(Map<String, dynamic> producto) {
    return (producto['producto_master_id'] ??
            producto['id_producto'] ??
            producto['id'] ??
            producto['nombre'] ??
            producto.hashCode)
        .toString();
  }

  static String name(Map<String, dynamic> producto) {
    return (producto['nombre'] ?? producto['name'] ?? 'Producto sin nombre').toString();
  }

  static String description(Map<String, dynamic> producto) {
    final text = (producto['descripcion'] ?? producto['description'] ?? '').toString().trim();
    return text.isEmpty ? 'Sin descripción disponible.' : text;
  }

  static String category(Map<String, dynamic> producto) {
    final categoria = producto['categoria'];

    if (categoria is Map) {
      return (categoria['nombre_categoria'] ?? categoria['nombre'] ?? '').toString();
    }

    return (producto['categoria_nombre'] ??
            producto['nombre_categoria'] ??
            producto['linea'] ??
            producto['categoria'] ??
            '')
        .toString();
  }

  static bool hasStockFlag(Map<String, dynamic> producto) {
    final value = producto['tiene_stock'];
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value != null) {
      final text = value.toString().toLowerCase().trim();
      if (text == '1' || text == 'true' || text == 'si' || text == 'sí') return true;
      if (text == '0' || text == 'false' || text == 'no') return false;
    }
    return stock(producto) > 0;
  }

  static int stock(Map<String, dynamic> producto) {
    final inventario = producto['inventario'];
    if (inventario is Map) {
      final stockValue = inventario['cantidad_stock'] ?? inventario['stock'];
      final parsedStock = toNullableInt(stockValue);
      if (parsedStock != null) return parsedStock;
    }

    final value = producto['stock'] ?? producto['cantidad_stock'] ?? 0;
    return toNullableInt(value) ?? 0;
  }

  static double price(Map<String, dynamic> producto) {
    final value = producto['precio_final'] ?? producto['precio_venta'] ?? producto['precio'] ?? 0;
    if (value is num) return value.toDouble();

    final raw = value
        .toString()
        .replaceAll('C\$', '')
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(raw) ?? 0;
  }

  static String priceText(Map<String, dynamic> producto) {
    return '\$ ${price(producto).toStringAsFixed(2)}';
  }

  static ProductImageData? principalImage(Map<String, dynamic> producto) {
    final imagesList = images(producto, limit: 1);
    return imagesList.isEmpty ? null : imagesList.first;
  }

  static List<ProductImageData> images(
    Map<String, dynamic> producto, {
    int limit = 6,
  }) {
    final result = <ProductImageData>[];

    void add(dynamic id, dynamic url) {
      final clean = (url ?? '').toString().trim();
      if (clean.isEmpty || clean.toLowerCase() == 'null') return;
      if (result.any((item) => item.url == clean)) return;

      result.add(
        ProductImageData(
          id: toNullableInt(id),
          url: clean,
        ),
      );
    }

    add(
      producto['producto_imagen_id'] ?? producto['imagen_id'],
      producto['imagen_url'] ?? producto['img'] ?? producto['imagen'],
    );

    final principal = producto['imagen_principal'];
    if (principal is Map) {
      add(
        principal['id'],
        principal['imagen_url'] ?? principal['img'] ?? principal['imagen'],
      );
    }

    final imagenes = producto['imagenes'];
    if (imagenes is List) {
      for (final img in imagenes) {
        if (img is Map) {
          add(
            img['id'],
            img['imagen_url'] ?? img['img'] ?? img['imagen'],
          );
        } else {
          add(null, img);
        }

        if (result.length >= limit) break;
      }
    }

    return result.take(limit).toList();
  }

  static Map<String, dynamic> productForCart(
    Map<String, dynamic> producto, {
    ProductImageData? selectedImage,
  }) {
    return {
      ...producto,
      'producto_master_id': producto['producto_master_id'] ?? producto['id_producto'] ?? producto['id'],
      'id_producto': producto['id_producto'] ?? producto['producto_master_id'] ?? producto['id'],
      'producto_imagen_id': selectedImage?.id ?? producto['producto_imagen_id'] ?? producto['imagen_id'],
      'imagen_url': selectedImage?.url ?? producto['imagen_url'] ?? producto['img'] ?? producto['imagen'],
      'img': selectedImage?.url ?? producto['img'] ?? producto['imagen_url'] ?? producto['imagen'],
    };
  }

  static int? toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value <= 0 ? null : value;
    if (value is num) return value <= 0 ? null : value.toInt();

    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;

    return parsed;
  }
}
