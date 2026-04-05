import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> producto;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final String nombre =
        (widget.producto['nombre'] ?? 'Producto sin nombre').toString();
    final String descripcion =
        (widget.producto['descripcion'] ?? 'Sin descripción').toString();
    final String precio =
        (widget.producto['precio'] ?? '\$0.00').toString();
    final String img = (widget.producto['img'] ?? '').toString();
    final String? descuento = widget.producto['descuento']?.toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _hovering
                        ? Colors.black.withAlpha(20)
                        : Colors.black.withAlpha(8),
                    blurRadius: _hovering ? 20 : 10,
                    offset: Offset(0, _hovering ? 10 : 4),
                  ),
                ],
                border: Border.all(
                  color: _hovering
                      ? Colors.black12
                      : Colors.grey[200]!, // Borde limpio y formal
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // Mismo color que el panel izquierdo de tu login web
                            color: Colors.grey[50], 
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Image.network(
                                img,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Container(
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE91E63), // Rosa del theme
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        if (descuento != null &&
                            descuento.isNotEmpty &&
                            descuento.toLowerCase() != 'null')
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63), // Acento rosa
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                descuento,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: AnimatedOpacity(
                            opacity: _hovering ? 1 : 0.0, // Solo se ve al hacer hover
                            duration: const Duration(milliseconds: 200),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(240),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ver detalle',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black, // Negro elegante
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Color(0xFFE91E63),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63).withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Text(
                            nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Colors.black, // Formalizado
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Expanded(
                            child: Text(
                              descripcion,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600], // Mismo del login
                                height: 1.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  precio,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    color: Colors.black, // Formalizado
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  // Botón negro en hover (como el de login), gris claro normal
                                  color: _hovering
                                      ? Colors.black
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: _hovering
                                      ? Colors.white
                                      : Colors.black87,
                                  size: 18,
                                ),
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