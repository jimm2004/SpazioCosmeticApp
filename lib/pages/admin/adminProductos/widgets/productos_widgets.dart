import 'package:flutter/material.dart';

import '../../../../models/producto_admin_model.dart';

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
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
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
                    fontWeight: FontWeight.w600,
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
        constraints: const BoxConstraints(maxWidth: 800),
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
            childAspectRatio: 0.75,
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProductoCardImage(
                  imagenUrl: producto.imagenUrl,
                  height: 80,
                  width: 80,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ProductoCardInfo(
                    producto: producto,
                    isGrid: false,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 8),
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
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    );

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
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProductoCardImage(
                  imagenUrl: producto.imagenUrl,
                  height: double.infinity,
                  width: double.infinity,
                  borderRadius: imageRadius,
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

class ProductoCardImage extends StatelessWidget {
  final String? imagenUrl;
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const ProductoCardImage({
    super.key,
    required this.imagenUrl,
    required this.height,
    required this.width,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool tieneImagen = imagenUrl != null && imagenUrl!.isNotEmpty;

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: tieneImagen
          ? ClipRRect(
              borderRadius: borderRadius,
              child: Image.network(
                imagenUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 40,
                  );
                },
              ),
            )
          : const Icon(
              Icons.inventory_2,
              color: Colors.grey,
              size: 40,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          producto.nombre,
          style: TextStyle(
            fontSize: isGrid ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
          maxLines: isGrid ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          isGrid
              ? '\$${producto.precioVenta.toStringAsFixed(2)}'
              : 'Precio: \$${producto.precioVenta.toStringAsFixed(2)}  •  Stock: ${producto.cantidadStock}',
          style: TextStyle(
            fontSize: isGrid ? 16 : 13,
            fontWeight: isGrid ? FontWeight.w800 : FontWeight.normal,
            color: isGrid ? Colors.green : Colors.grey.shade600,
          ),
        ),
        if (isGrid) ...[
          const SizedBox(height: 4),
          Text(
            'Stock: ${producto.cantidadStock}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 8),
        ProductoVisibilityBadge(esVisible: esVisible),
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
          fontWeight: FontWeight.bold,
          color: esVisible ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}