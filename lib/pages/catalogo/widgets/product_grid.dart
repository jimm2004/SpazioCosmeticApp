import 'package:flutter/material.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> productos;
  final ValueChanged<Map<String, dynamic>> onProductTap;

  const ProductGrid({
    super.key,
    required this.productos,
    required this.onProductTap,
  });

  bool _tieneFoto(Map<String, dynamic> producto) {
    final img = (producto['img'] ?? '').toString().trim();
    return img.isNotEmpty && img.toLowerCase() != 'null';
  }

  @override
  Widget build(BuildContext context) {
    final productosConFoto =
        productos.where((producto) => _tieneFoto(producto)).toList();

    if (productosConFoto.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Center(
          child: Text(
            'No hay productos con imagen para mostrar.',
            style: TextStyle(fontSize: 16),
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
          int crossAxisCount;
          double childAspectRatio;

          if (constraints.maxWidth >= 1200) {
            crossAxisCount = 4;
            childAspectRatio = 0.78;
          } else if (constraints.maxWidth >= 900) {
            crossAxisCount = 3;
            childAspectRatio = 0.76;
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 2;
            childAspectRatio = 0.80;
          } else {
            crossAxisCount = 1;
            childAspectRatio = 1.05;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productosConFoto.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final producto = productosConFoto[index];

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 280 + (index * 90)),
                tween: Tween(begin: 0, end: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 25 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ProductCard(
                  producto: producto,
                  onTap: () => onProductTap(producto),
                ),
              );
            },
          );
        },
      ),
    );
  }
}