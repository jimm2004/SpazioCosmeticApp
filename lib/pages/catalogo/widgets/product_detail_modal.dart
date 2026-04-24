import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controllers/catalogo/cart_controller.dart';
import 'cart_modal.dart';

class ProductDetailModal extends StatelessWidget {
  final Map<String, dynamic> producto;
  final String phone;

  const ProductDetailModal({
    super.key,
    required this.producto,
    this.phone = '50578496665',
  });

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    final String nombre = (producto['nombre'] ?? 'Producto').toString();
    final String descripcion =
        (producto['descripcion'] ?? 'Sin descripción disponible').toString();
    final String precio = (producto['precio'] ?? '\$0.00').toString();
    final String imagen = (producto['img'] ?? '').toString();

    int cantidad = 1;

    Future<void> abrirWhatsApp() async {
      final msg = Uri.encodeComponent(
        'Hola, me interesa este producto:\n'
        'Producto: $nombre\n'
        'Precio: $precio\n'
        'Detalle: $descripcion',
      );

      final url = Uri.parse('https://wa.me/$phone?text=$msg');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    return StatefulBuilder(
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBFC),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        color: Colors.white,
                        child: imagen.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                              )
                            : Image.network(
                                imagen,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 56,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Disponible',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      precio,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Cantidad',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (cantidad > 1) {
                              setModalState(() => cantidad--);
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$cantidad',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setModalState(() => cantidad++);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          cart.addProducto(producto, cantidad: cantidad);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$nombre agregado al carrito',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context); // Cierra el modal después de agregar
                        },
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Agregar al carrito'),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              cart.addProducto(producto, cantidad: cantidad);
                              Navigator.pop(context);
                              // Aquí es importante llamar al modal del carrito
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const CartModal(),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Ver carrito'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: abrirWhatsApp,
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
      },
    );
  }
}