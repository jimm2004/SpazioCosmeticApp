import 'package:flutter/material.dart';

import '../../../controllers/catalogo/cart_controller.dart';
import '../cart_page.dart';

class ProductDiscoveryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> productos;
  final Future<void> Function()? onCartChanged;

  const ProductDiscoveryGrid({
    super.key,
    required this.productos,
    this.onCartChanged,
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 700 ? 16 : 40,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int count;
          double ratio;

          if (constraints.maxWidth >= 1280) {
            count = 4;
            ratio = .72;
          } else if (constraints.maxWidth >= 920) {
            count = 3;
            ratio = .70;
          } else if (constraints.maxWidth >= 620) {
            count = 2;
            ratio = .74;
          } else {
            count = 1;
            ratio = .88;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 22,
              mainAxisSpacing: 22,
              childAspectRatio: ratio,
            ),
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 240 + (index * 45)),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 22 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ProductShowcaseCard(
                  producto: productos[index],
                  onCartChanged: onCartChanged,
                ),
              );
            },
          );
        },
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
  final PageController _pageController = PageController();
  int _index = 0;
  bool _hover = false;
  bool _adding = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addPrincipal() async {
    if (_adding) return;

    setState(() => _adding = true);
    final imagen = ProductUiHelper.images(widget.producto).isEmpty
        ? null
        : ProductUiHelper.images(widget.producto)[_index.clamp(0, ProductUiHelper.images(widget.producto).length - 1).toInt()];

    final payload = ProductUiHelper.productForCart(
      widget.producto,
      selectedImage: imagen,
    );

    final ok = await CartController.instance.agregarProducto(
      productoMasterId: ProductUiHelper._toNullableInt(
            payload['producto_master_id'] ?? payload['id_producto'] ?? payload['id'],
          ) ??
          0,
      productoImagenId: ProductUiHelper._toNullableInt(
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
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(
        producto: widget.producto,
        initialIndex: _index,
        onCartChanged: widget.onCartChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = ProductUiHelper.images(widget.producto);
    final nombre = ProductUiHelper.name(widget.producto);
    final descripcion = ProductUiHelper.description(widget.producto);
    final categoria = ProductUiHelper.category(widget.producto);
    final precio = ProductUiHelper.priceText(widget.producto);
    final stock = ProductUiHelper.stock(widget.producto);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openDetail,
            borderRadius: BorderRadius.circular(28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _hover ? const Color(0xFFE91E63).withOpacity(.25) : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_hover ? .12 : .055),
                    blurRadius: _hover ? 24 : 12,
                    offset: Offset(0, _hover ? 12 : 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 62,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFFFDFBFC),
                            child: images.isEmpty
                                ? const Center(
                                    child: Icon(Icons.image_not_supported_outlined, size: 56, color: Colors.grey),
                                  )
                                : PageView.builder(
                                    controller: _pageController,
                                    itemCount: images.length,
                                    onPageChanged: (value) => setState(() => _index = value),
                                    itemBuilder: (_, i) {
                                      return Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Image.network(
                                          images[i].url,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey,
                                            size: 48,
                                          ),
                                          loadingBuilder: (_, child, progress) {
                                            if (progress == null) return child;
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFFE91E63),
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              categoria.isEmpty ? 'Producto' : categoria,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            right: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.68),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${_index + 1}/${images.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 38,
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
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.15),
                                ),
                              ),
                              if (stock > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Stock',
                                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w800),
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
                              IconButton.filled(
                                onPressed: _adding ? null : _addPrincipal,
                                style: IconButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
                                icon: _adding
                                    ? const SizedBox(
                                        width: 17,
                                        height: 17,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
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
  late PageController _controller;
  late int _selected;
  int _cantidad = 1;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    final images = ProductUiHelper.images(widget.producto);
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
    final images = ProductUiHelper.images(widget.producto);
    final selectedImage = images.isEmpty ? null : images[_selected.clamp(0, images.length - 1).toInt()];
    final payload = ProductUiHelper.productForCart(widget.producto, selectedImage: selectedImage);

    setState(() => _adding = true);
    final ok = await CartController.instance.agregarProducto(
      productoMasterId: ProductUiHelper._toNullableInt(
            payload['producto_master_id'] ?? payload['id_producto'] ?? payload['id'],
          ) ??
          0,
      productoImagenId: ProductUiHelper._toNullableInt(
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
    Navigator.pop(context);

    if (openCart) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ProductUiHelper.images(widget.producto);
    final nombre = ProductUiHelper.name(widget.producto);
    final descripcion = ProductUiHelper.description(widget.producto);
    final precio = ProductUiHelper.priceText(widget.producto);
    final categoria = ProductUiHelper.category(widget.producto);

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
                        style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w800),
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
                  height: MediaQuery.of(context).size.width < 680 ? 370 : 440,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBFC),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: images.isEmpty
                      ? const Center(child: Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey))
                      : PageView.builder(
                          controller: _controller,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _selected = i),
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.network(
                                images[i].url,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined, size: 58, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                ),
                if (images.length > 1) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
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
                                  child: Image.network(
                                    images[i].url,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 10),
                Text(
                  descripcion,
                  style: const TextStyle(color: Colors.black54, height: 1.55, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Text(
                  precio,
                  style: const TextStyle(fontSize: 30, color: Color(0xFFE91E63), fontWeight: FontWeight.w900),
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
                      const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w900)),
                      const Spacer(),
                      IconButton(
                        onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_cantidad', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      IconButton(
                        onPressed: () => setState(() => _cantidad++),
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
                        onPressed: _adding ? null : () => _add(),
                        icon: _adding
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_shopping_cart),
                        label: Text(_adding ? 'Agregando...' : 'Agregar al carrito'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _adding ? null : () => _add(openCart: true),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Carrito'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

class ProductImageData {
  final int? id;
  final String url;

  const ProductImageData({required this.id, required this.url});
}

class ProductUiHelper {
  static String name(Map<String, dynamic> producto) {
    return (producto['nombre'] ?? producto['name'] ?? 'Producto sin nombre').toString();
  }

  static String description(Map<String, dynamic> producto) {
    final text = (producto['descripcion'] ?? producto['description'] ?? '').toString().trim();
    return text.isEmpty ? 'Sin descripción disponible.' : text;
  }

  static String category(Map<String, dynamic> producto) {
    return (producto['categoria_nombre'] ?? producto['categoria'] ?? '').toString();
  }

  static int stock(Map<String, dynamic> producto) {
    final value = producto['stock'] ?? producto['cantidad_stock'] ?? 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double price(Map<String, dynamic> producto) {
    final value = producto['precio_final'] ?? producto['precio_venta'] ?? producto['precio'] ?? 0;
    if (value is num) return value.toDouble();
    final raw = value.toString().replaceAll('C\$', '').replaceAll('\$', '').replaceAll(',', '').trim();
    return double.tryParse(raw) ?? 0;
  }

  static String priceText(Map<String, dynamic> producto) {
    return '\$ ${price(producto).toStringAsFixed(2)}';
  }

  static List<ProductImageData> images(Map<String, dynamic> producto) {
    final result = <ProductImageData>[];

    void add(dynamic id, dynamic url) {
      final clean = (url ?? '').toString().trim();
      if (clean.isEmpty || clean.toLowerCase() == 'null') return;
      if (result.any((item) => item.url == clean)) return;
      result.add(ProductImageData(id: _toNullableInt(id), url: clean));
    }

    add(producto['producto_imagen_id'] ?? producto['imagen_id'], producto['imagen_url'] ?? producto['img'] ?? producto['imagen']);

    final principal = producto['imagen_principal'];
    if (principal is Map) {
      add(principal['id'], principal['imagen_url'] ?? principal['img'] ?? principal['imagen']);
    }

    final imagenes = producto['imagenes'];
    if (imagenes is List) {
      for (final img in imagenes.take(2)) {
        if (img is Map) {
          add(img['id'], img['imagen_url'] ?? img['img'] ?? img['imagen']);
        } else {
          add(null, img);
        }
      }
    }

    return result.take(2).toList();
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

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value <= 0 ? null : value;
    if (value is num) return value <= 0 ? null : value.toInt();
    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }
}
