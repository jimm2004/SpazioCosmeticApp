import 'package:flutter/material.dart';

import '../../controllers/catalogo/cart_controller.dart';
import 'checkout_page.dart';
import 'mood_palette.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController cart = CartController.instance;

  @override
  void initState() {
    super.initState();
    cart.addListener(_sync);
    cart.cargarCarrito();
  }

  @override
  void dispose() {
    cart.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  Future<bool> _confirm(String title, String message, String action) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white), child: Text(action)),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _vaciar() async {
    final okConfirm = await _confirm('Vaciar carrito', '¿Querés quitar todos los productos del carrito?', 'Sí, vaciar');
    if (!okConfirm) return;
    final ok = await cart.vaciarCarrito();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Carrito vacío' : cart.error ?? 'Error'), backgroundColor: ok ? Colors.green : Colors.redAccent));
  }

  Future<void> _quitar(int id, String nombre) async {
    final okConfirm = await _confirm('Quitar producto', '¿Querés quitar "$nombre" del carrito?', 'Quitar');
    if (!okConfirm) return;
    final ok = await cart.quitarItem(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Producto eliminado' : cart.error ?? 'Error'), backgroundColor: ok ? Colors.green : Colors.redAccent));
  }

  void _checkout() {
    if (cart.items.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoodPalette.background,
      appBar: AppBar(
        backgroundColor: MoodPalette.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoodPalette.text),
        title: const Text('Mi carrito', style: TextStyle(color: MoodPalette.text, fontWeight: FontWeight.w900)),
        actions: [
          if (cart.items.isNotEmpty) IconButton(onPressed: _vaciar, icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent)),
        ],
      ),
      body: cart.loading
          ? const Center(child: CircularProgressIndicator(color: MoodPalette.pink))
          : cart.items.isEmpty
              ? const _EmptyCart()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [MoodPalette.cardShadow(.07)]),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 88,
                              height: 88,
                              color: MoodPalette.softPink,
                              child: item.imagenUrl.isEmpty ? const Icon(Icons.image_outlined) : Image.network(item.imagenUrl, fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: MoodPalette.text)),
                                const SizedBox(height: 5),
                                Text('\$ ${item.precioUnitario.toStringAsFixed(2)}', style: const TextStyle(color: MoodPalette.pink, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _QtyButton(icon: Icons.remove, onTap: () => cart.editarCantidad(item.detalleId, item.cantidad - 1)),
                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.w900))),
                                    _QtyButton(icon: Icons.add, onTap: () => cart.editarCantidad(item.detalleId, item.cantidad + 1)),
                                    const Spacer(),
                                    IconButton(onPressed: () => _quitar(item.detalleId, item.nombre), icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [MoodPalette.cardShadow(.11)], borderRadius: const BorderRadius.vertical(top: Radius.circular(26))),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('\$ ${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: MoodPalette.pink)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _checkout,
                        icon: const Icon(Icons.payment_rounded),
                        label: const Text('Continuar pedido'),
                        style: ElevatedButton.styleFrom(backgroundColor: MoodPalette.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: MoodPalette.softPink, shape: BoxShape.circle), child: Icon(icon, size: 18, color: MoodPalette.pink)),
      );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: MoodPalette.pink),
            SizedBox(height: 12),
            Text('Tu carrito está vacío', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            SizedBox(height: 6),
            Text('Agregá productos del catálogo para iniciar el pedido.', textAlign: TextAlign.center),
          ]),
        ),
      );
}
