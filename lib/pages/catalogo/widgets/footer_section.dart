import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  final VoidCallback? onShopNow;
  final VoidCallback? onNewsTap;
  final VoidCallback? onWhatsAppTap;

  const FooterSection({
    super.key,
    this.onShopNow,
    this.onNewsTap,
    this.onWhatsAppTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 850;

    final footerInfo = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: _FooterBrand()),
                const SizedBox(width: 30),
                const Expanded(child: _FooterContacto()),
                const SizedBox(width: 30),
                Expanded(
                  child: _FooterAtencion(onWhatsAppTap: onWhatsAppTap),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterBrand(),
                const SizedBox(height: 25),
                const _FooterContacto(),
                const SizedBox(height: 25),
                _FooterAtencion(onWhatsAppTap: onWhatsAppTap),
              ],
            ),
    );

    final promoTop = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE91E63),
            Color(0xFFF06292),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: isWide
          ? Row(
              children: [
                const Expanded(child: _PromoText()),
                const SizedBox(width: 20),
                _PromoButtons(
                  onNewsTap: onNewsTap,
                  onShopNow: onShopNow,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PromoText(),
                const SizedBox(height: 20),
                _PromoButtons(
                  onNewsTap: onNewsTap,
                  onShopNow: onShopNow,
                ),
              ],
            ),
    );

    return Container(
      width: double.infinity,
      color: const Color(0xFFFCFAFB),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: promoTop,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: footerInfo,
          ),
          const Divider(height: 1, color: Color(0xFFEAEAEA)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              '© 2026 SPAZIO COSMETIC. Todos los derechos reservados.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoText extends StatelessWidget {
  const _PromoText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Novedades y eventos',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Promociones, lanzamientos y productos destacados.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PromoButtons extends StatelessWidget {
  final VoidCallback? onShopNow;
  final VoidCallback? onNewsTap;

  const _PromoButtons({
    required this.onShopNow,
    required this.onNewsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: onNewsTap,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Ver novedades'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFE91E63),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onShopNow,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Comprar ahora'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPAZIO COSMETIC',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Color(0xFF1F1F1F),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Catálogo moderno, ventas más ágiles y una experiencia de compra más bonita que una reunión cancelada.',
          style: TextStyle(
            height: 1.7,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _FooterContacto extends StatelessWidget {
  const _FooterContacto();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Text('Managua, Nicaragua'),
        SizedBox(height: 6),
        Text('Envíos a todo el país'),
        SizedBox(height: 6),
        Text('Horario: 8:00 AM - 6:00 PM'),
      ],
    );
  }
}

class _FooterAtencion extends StatelessWidget {
  final VoidCallback? onWhatsAppTap;

  const _FooterAtencion({required this.onWhatsAppTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atención',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        const Text('Pedidos personalizados'),
        const SizedBox(height: 6),
        const Text('Métodos de pago'),
        const SizedBox(height: 6),
        const Text('Seguimiento de pedidos'),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onWhatsAppTap,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Escribir por WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}