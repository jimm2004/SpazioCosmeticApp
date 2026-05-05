import 'package:flutter/foundation.dart';

import '../../models/catalogo/carrito_model.dart';
import '../../services/catalogo_service.dart';

class CartController extends ChangeNotifier {
  static final CartController instance = CartController._internal();
  CartController._internal();

  final CatalogoService _service = CatalogoService();

  CarritoModel? cart;
  bool loading = false;
  String? error;

  int get totalItems => cart?.totalItems ?? 0;
  double get subtotal => cart?.subtotal ?? 0;
  double get total => subtotal;
  List<CarritoItemModel> get items => cart?.items ?? [];

  Future<void> cargarCarrito() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      cart = await _service.verCarrito();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarProducto({
    required int productoMasterId,
    int? productoImagenId,
    int cantidad = 1,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      cart = await _service.agregarAlCarrito(
        productoMasterId: productoMasterId,
        productoImagenId: productoImagenId,
        cantidad: cantidad,
      );
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> editarCantidad(int detalleId, int cantidad) async {
    if (cantidad <= 0) return quitarItem(detalleId);
    loading = true;
    error = null;
    notifyListeners();
    try {
      cart = await _service.editarItemCarrito(detalleId: detalleId, cantidad: cantidad);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> quitarItem(int detalleId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      cart = await _service.quitarItemCarrito(detalleId);
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> limpiar() async {
    return vaciarCarrito();
  }

  Future<bool> vaciarCarrito() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      cart = await _service.vaciarCarrito();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
