import 'package:flutter/material.dart';

import '../../../../models/producto_admin_model.dart';

class AdminProductosStatsHeader extends StatelessWidget {
  final int total;
  final int visibles;
  final int conFotos;
  final int sinFotos;

  const AdminProductosStatsHeader({
    super.key,
    required this.total,
    required this.visibles,
    required this.conFotos,
    required this.sinFotos,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5E35B1),
                  Color(0xFF7E57C2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5E35B1).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel visual de productos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Revisa fotos, precio final, stock y visibilidad.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.inventory_2_rounded,
                        label: 'Total',
                        value: '$total',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.visibility_rounded,
                        label: 'Visibles',
                        value: '$visibles',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.photo_library_rounded,
                        label: 'Con fotos',
                        value: '$conFotos',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.image_not_supported_rounded,
                        label: 'Sin fotos',
                        value: '$sinFotos',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProductoSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const AdminProductoSearchBox({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Buscar producto, descripción o precio...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF5E35B1),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: onClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductoEmptyState extends StatelessWidget {
  const ProductoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron productos',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intenta buscar con otra palabra',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProductoListView extends StatelessWidget {
  final List<ProductoAdminModel> productos;
  final Future<void> Function(int idProducto) onTapProducto;

  const ProductoListView({
    super.key,
    required this.productos,
    required this.onTapProducto,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];

            return ProductoListCard(
              producto: producto,
              onTap: () {
                FocusScope.of(context).unfocus();
                onTapProducto(producto.idProducto);
              },
            );
          },
        ),
      ),
    );
  }
}

class ProductoGridView extends StatelessWidget {
  final List<ProductoAdminModel> productos;
  final int crossAxisCount;
  final Future<void> Function(int idProducto) onTapProducto;

  const ProductoGridView({
    super.key,
    required this.productos,
    required this.crossAxisCount,
    required this.onTapProducto,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: productos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];

            return ProductoGridCard(
              producto: producto,
              onTap: () {
                FocusScope.of(context).unfocus();
                onTapProducto(producto.idProducto);
              },
            );
          },
        ),
      ),
    );
  }
}

class ProductoListCard extends StatelessWidget {
  final ProductoAdminModel producto;
  final VoidCallback onTap;

  const ProductoListCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalFotos = producto.totalImagenes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProductoImagesPreview(
                  producto: producto,
                  height: 96,
                  width: 118,
                  borderRadius: BorderRadius.circular(18),
                  mode: ProductoImagesPreviewMode.list,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ProductoCardInfo(
                    producto: producto,
                    isGrid: false,
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: totalFotos >= 2
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalFotos/2',
                        style: TextStyle(
                          color: totalFotos >= 2
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductoGridCard extends StatelessWidget {
  final ProductoAdminModel producto;
  final VoidCallback onTap;

  const ProductoGridCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius imageRadius = const BorderRadius.only(
      topLeft: Radius.circular(22),
      topRight: Radius.circular(22),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProductoImagesPreview(
                  producto: producto,
                  height: double.infinity,
                  width: double.infinity,
                  borderRadius: imageRadius,
                  mode: ProductoImagesPreviewMode.grid,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ProductoCardInfo(
                  producto: producto,
                  isGrid: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ProductoImagesPreviewMode {
  list,
  grid,
}

class ProductoImagesPreview extends StatelessWidget {
  final ProductoAdminModel producto;
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final ProductoImagesPreviewMode mode;

  const ProductoImagesPreview({
    super.key,
    required this.producto,
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final List<ProductoImagenAdminModel> fotos = producto.imagenes;

    final String? foto1 = fotos.isNotEmpty
        ? fotos[0].imagenUrl
        : producto.imagenUrl;

    final String? foto2 = fotos.length > 1 ? fotos[1].imagenUrl : null;

    final bool tieneFoto1 = _tieneUrl(foto1);
    final bool tieneFoto2 = _tieneUrl(foto2);

    final bool grid = mode == ProductoImagesPreviewMode.grid;

    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            if (tieneFoto1 && tieneFoto2)
              Row(
                children: [
                  Expanded(
                    child: ProductoImageTile(
                      imagenUrl: foto1,
                      label: '1',
                      isPrincipal: fotos.isNotEmpty
                          ? fotos[0].esPrincipal
                          : true,
                      borderRadius: BorderRadius.zero,
                      iconSize: grid ? 38 : 30,
                    ),
                  ),
                  Container(
                    width: 2,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: ProductoImageTile(
                      imagenUrl: foto2,
                      label: '2',
                      isPrincipal: fotos.length > 1
                          ? fotos[1].esPrincipal
                          : false,
                      borderRadius: BorderRadius.zero,
                      iconSize: grid ? 38 : 30,
                    ),
                  ),
                ],
              )
            else if (tieneFoto1)
              ProductoImageTile(
                imagenUrl: foto1,
                label: '1',
                isPrincipal: fotos.isNotEmpty
                    ? fotos[0].esPrincipal
                    : true,
                borderRadius: BorderRadius.zero,
                iconSize: grid ? 42 : 32,
              )
            else
              ProductoImagePlaceholder(
                iconSize: grid ? 48 : 34,
              ),

            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${producto.totalImagenes}/2 fotos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _tieneUrl(String? value) {
    final text = value?.trim() ?? '';

    return text.isNotEmpty && text.toLowerCase() != 'null';
  }
}

class ProductoImageTile extends StatelessWidget {
  final String? imagenUrl;
  final String label;
  final bool isPrincipal;
  final BorderRadius borderRadius;
  final double iconSize;

  const ProductoImageTile({
    super.key,
    required this.imagenUrl,
    required this.label,
    required this.isPrincipal,
    required this.borderRadius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final url = imagenUrl?.trim() ?? '';
    final bool tieneImagen = url.isNotEmpty && url.toLowerCase() != 'null';

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: borderRadius,
          ),
          child: tieneImagen
              ? ClipRRect(
                  borderRadius: borderRadius,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ProductoImagePlaceholder(iconSize: iconSize);
                    },
                  ),
                )
              : ProductoImagePlaceholder(iconSize: iconSize),
        ),
        Positioned(
          top: 7,
          left: 7,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Foto $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (isPrincipal)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF5E35B1).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProductoImagePlaceholder extends StatelessWidget {
  final double iconSize;

  const ProductoImagePlaceholder({
    super.key,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_rounded,
          size: iconSize,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

class ProductoCardInfo extends StatelessWidget {
  final ProductoAdminModel producto;
  final bool isGrid;

  const ProductoCardInfo({
    super.key,
    required this.producto,
    required this.isGrid,
  });

  @override
  Widget build(BuildContext context) {
    final bool esVisible = producto.activo ?? true;
    final double precioFinal = producto.precioFinal > 0
        ? producto.precioFinal
        : producto.precioVenta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.nombre,
          style: TextStyle(
            fontSize: isGrid ? 14 : 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C3E50),
            height: 1.15,
          ),
          maxLines: isGrid ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Flexible(
              child: Text(
                '\$${precioFinal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isGrid ? 17 : 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (precioFinal != producto.precioVenta)
              Flexible(
                child: Text(
                  'Base \$${producto.precioVenta.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isGrid ? 11 : 12,
                    color: Colors.grey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Stock: ${producto.cantidadStock}',
          style: TextStyle(
            fontSize: isGrid ? 12 : 13,
            color: producto.cantidadStock > 0
                ? Colors.grey.shade700
                : Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ProductoVisibilityBadge(esVisible: esVisible),
            ProductoPhotoBadge(totalFotos: producto.totalImagenes),
          ],
        ),
      ],
    );
  }
}

class ProductoVisibilityBadge extends StatelessWidget {
  final bool esVisible;

  const ProductoVisibilityBadge({
    super.key,
    required this.esVisible,
  });

  @override
  Widget build(BuildContext context) {
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
          fontWeight: FontWeight.w800,
          color: esVisible ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}

class ProductoPhotoBadge extends StatelessWidget {
  final int totalFotos;

  const ProductoPhotoBadge({
    super.key,
    required this.totalFotos,
  });

  @override
  Widget build(BuildContext context) {
    final bool completo = totalFotos >= 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completo
            ? const Color(0xFF5E35B1).withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        completo ? '2 fotos' : '$totalFotos/2 fotos',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: completo
              ? const Color(0xFF5E35B1)
              : Colors.orange.shade700,
        ),
      ),
    );
  }
}