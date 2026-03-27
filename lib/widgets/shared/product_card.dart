// lib/widgets/product_card.dart
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent, // Si es web, quitamos el hover gris por defecto
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen del producto con Etiqueta de descuento
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white, // Fondo blanco limpio
                  child: Image.network(
                    producto['img']!,
                    fit: BoxFit.contain, // Contain para que se vea el envase completo
                  ),
                ),
                // Etiqueta verde/roja de descuento (esquina superior derecha)
                if (producto['descuento'] != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green, // Color de etiqueta (ajusta según necesites)
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        producto['descuento'],
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Nombre del producto
          Text(
            producto['nombre'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          
          // Estrellas (Rating)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < (producto['rating'] as int) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 14,
              );
            }),
          ),
          const SizedBox(height: 6),
          
          // Precio
          Text(
            producto['precio'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }
}