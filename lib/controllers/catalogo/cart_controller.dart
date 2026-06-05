import 'package:flutter/material.dart';

class CartItem {
  final Map<String, dynamic> producto;
  int cantidad;

  CartItem({
    required this.producto,
    this.cantidad = 1,
  });

  String get id => (producto['id'] ?? '').toString();
  String get nombre => (producto['nombre'] ?? '').toString();
  String get precioTexto => (producto['precio'] ?? '\$0.00').toString();

  double get precioNumero {
    final raw = producto['precio_num'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  String get imagen => (producto['img'] ?? '').toString();
  String get descripcion => (producto['descripcion'] ?? '').toString();

  double get subtotal => precioNumero * cantidad;
}

class CartController extends ChangeNotifier {
  CartController._();
  static final CartController instance = CartController._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems =>
      _items.fold(0, (total, item) => total + item.cantidad);

  double get total =>
      _items.fold(0, (total, item) => total + item.subtotal);

  int cantidadDeProducto(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return 0;
    return _items[index].cantidad;
  }

  bool estaEnCarrito(String id) => cantidadDeProducto(id) > 0;

  void addProducto(
    Map<String, dynamic> producto, {
    int cantidad = 1,
  }) {
    final id = (producto['id'] ?? '').toString();
    if (id.isEmpty) return;

    final index = _items.indexWhere((item) => item.id == id);

    if (index >= 0) {
      _items[index].cantidad += cantidad;
    } else {
      _items.add(
        CartItem(
          producto: producto,
          cantidad: cantidad,
        ),
      );
    }

    notifyListeners();
  }

  void aumentar(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].cantidad++;
      notifyListeners();
    }
  }

  void disminuir(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].cantidad > 1) {
        _items[index].cantidad--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void eliminar(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void limpiar() {
    _items.clear();
    notifyListeners();
  }

  String resumenParaWhatsApp() {
    final buffer = StringBuffer();
    buffer.writeln('Hola, este es mi carrito:');
    buffer.writeln('');

    for (final item in _items) {
      buffer.writeln(
        '- ${item.nombre} x${item.cantidad} = \$${item.subtotal.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('');
    buffer.writeln('Total: \$${total.toStringAsFixed(2)}');

    return buffer.toString();
  }
}