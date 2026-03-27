// lib/pages/catalogo_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth/auth_controller.dart';
import '../auth/auth_page.dart';

// Importamos los widgets que crearemos a continuación
import '../../widgets/shared/hero_section.dart';
import '../../widgets/shared/product_grid.dart';
import '../../widgets/shared/footer_section.dart';

class CatalogoPage extends StatefulWidget {
  final String userName;

  const CatalogoPage({super.key, required this.userName});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final String phone = "50578496665";
  final AuthController _authController = AuthController();

  // Datos de ejemplo (idealmente vendrían de tu API)
  final List<Map<String, dynamic>> productos = const [
    {
      'id': 'P6',
      'nombre': 'Originals Kaval Windbreaker',
      'precio': '€26.24',
      'rating': 5,
      'descuento': '-10%',
      'img': 'https://picsum.photos/seed/p6/600'
    },
    {
      'id': 'P7',
      'nombre': 'Juicy Couture Quilted Terry',
      'precio': '€43.80',
      'rating': 4,
      'descuento': null,
      'img': 'https://picsum.photos/seed/p7/600'
    },
    {
      'id': 'P11',
      'nombre': 'Madden by Steve Madden',
      'precio': '€13.79',
      'rating': 5,
      'descuento': '-5%',
      'img': 'https://picsum.photos/seed/p11/600'
    },
    {
      'id': 'P12',
      'nombre': 'Trans-Weight Hooded Wind',
      'precio': '€14.52',
      'rating': 0,
      'descuento': null,
      'img': 'https://picsum.photos/seed/p12/600'
    },
  ];

  Future<void> _launchWA(String msg) async {
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("No se pudo abrir WhatsApp");
    }
  }

  Future<void> _logout() async {
    try {
      await _authController.logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _launchWA("Hola Spazio Cosmetic, me gustaría consultar sobre sus productos."),
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Banner Principal (Inspirado en Argima)
            const HeroSection(),
            
            const SizedBox(height: 60),
            
            // 2. Título de Sección
            _buildSectionTitle('New Arrivals', 'Add our new arrivals to your weekly lineup'),
            
            const SizedBox(height: 30),
            
            // 3. Grid de Productos
            ProductGrid(
              productos: productos,
              onProductTap: (nombre) => _launchWA("Me interesa el producto: $nombre"),
            ),
            
            const SizedBox(height: 60),
            
            // 4. Footer
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // AQUÍ SE AGREGA TU LOGO
          Image.asset(
            'assets/img/Logo.png',
            height: 32, // Ajusta este tamaño si lo ves muy grande o pequeño
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text(
            '',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1.5,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          // Menú de navegación estilo web (se oculta en móviles pequeños)
          if (MediaQuery.of(context).size.width > 800) ...[
            _navItem('Home'),
            _navItem('About Us'),
            _navItem('Shop'),
            _navItem('Contact Us'),
          ],
        ],
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              'Hola, ${widget.userName}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.pink[400]),
            ),
          ),
        ),
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.black),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _navItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      children: [
        const Icon(Icons.local_florist, color: Colors.pink, size: 30), // Icono decorativo superior
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }
}