// lib/widgets/footer_section.dart
import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA), // Fondo gris muy claro
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          // Un pequeño banner promocional abajo (como en la imagen "Natural Skincare 40% OFF")
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFEBCFCB), // Color rosa pálido
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'NATURAL SKINCARE',
                  style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 14),
                ),
                const SizedBox(height: 10),
                const Text(
                  '40% OFF',
                  style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('SHOP NOW'),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Info del Footer
          const Text(
            'SPAZIO COSMETIC',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Managua, Nicaragua • Envíos a todo el país',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.black12),
          const SizedBox(height: 20),
          const Text(
            '© 2026 SPAZIO PROFESSIONAL. Todos los derechos reservados.',
            style: TextStyle(color: Colors.black38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}