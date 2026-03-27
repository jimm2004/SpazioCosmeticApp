// lib/widgets/hero_section.dart
import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF3EBE6), // Color crema/rosado claro de fondo
      padding: EdgeInsets.symmetric(
        vertical: 60,
        horizontal: isWide ? 100 : 20,
      ),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Imagen del producto (En la imagen es una polvera de maquillaje)
          Expanded(
            flex: isWide ? 1 : 0,
            child: Image.network(
              'https://picsum.photos/id/1025/600/400', // Reemplaza con una imagen real tuya (fondo transparente ideal)
              height: isWide ? 400 : 250,
              fit: BoxFit.contain,
            ),
          ),
          if (isWide) const SizedBox(width: 50),
          if (!isWide) const SizedBox(height: 30),
          
          // Texto de la derecha
          Expanded(
            flex: isWide ? 1 : 0,
            child: Column(
              crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                const Text(
                  'REAL COVER PINK CUSHION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'FACE MAKEUP\nSALE 40% OFF',
                  textAlign: isWide ? TextAlign.left : TextAlign.center,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE96D71), // Rosa fuerte del botón
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SHOP NOW',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}