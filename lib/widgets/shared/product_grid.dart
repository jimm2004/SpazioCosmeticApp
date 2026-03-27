// lib/widgets/product_grid.dart
import 'package:flutter/material.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> productos;
  final Function(String) onProductTap;

  const ProductGrid({
    super.key,
    required this.productos,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 30,
              mainAxisSpacing: 40,
              childAspectRatio: 0.65, // Ajusta esto si la tarjeta se corta
            ),
            itemBuilder: (context, index) => ProductCard(
              producto: productos[index],
              onTap: () => onProductTap(productos[index]['nombre']),
            ),
          );
        },
      ),
    );
  }
}