import 'package:flutter/foundation.dart';

import '../../models/catalogo/carrito_model.dart';
import '../../services/catalogo_service.dart';

class CartController extends ChangeNotifier {
  static final CartController instance = CartController._internal();
  final CatalogoService _service = CatalogoService();

  CartController._internal();

  bool loading = false;
  bool saving = false;
  String? error;
  CarritoModel? carrito;

  List<CarritoItemModel> get items => carrito?.items ?? const <CarritoItemModel>[];
  double get subtotal => carrito?.subtotal ?? 0;
  int get totalItems => carrito?.totalItems ?? 0;

  Future<void> cargarCarrito() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      carrito = await _service.verCarrito();
    } catch (e) {
      error = _friendlyError(e);
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
    if (productoMasterId <= 0) {
      error = 'Producto inválido.';
      notifyListeners();
      return false;
    }
    if (cantidad <= 0) {
      error = 'La cantidad debe ser mayor que cero.';
      notifyListeners();
      return false;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      carrito = await _service.agregarAlCarrito(
        productoMasterId: productoMasterId,
        productoImagenId: productoImagenId,
        cantidad: cantidad,
      );
      return true;
    } catch (e) {
      error = _friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> editarCantidad(int detalleId, int cantidad) async {
    if (detalleId <= 0) {
      error = 'Ítem inválido.';
      notifyListeners();
      return false;
    }
    if (cantidad <= 0) return quitarItem(detalleId);
    saving = true;
    error = null;
    notifyListeners();
    try {
      carrito = await _service.editarItemCarrito(detalleId: detalleId, cantidad: cantidad);
      return true;
    } catch (e) {
      error = _friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> quitarItem(int detalleId) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      carrito = await _service.quitarItemCarrito(detalleId);
      return true;
    } catch (e) {
      error = _friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> vaciarCarrito() async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      carrito = await _service.vaciarCarrito();
      return true;
    } catch (e) {
      error = _friendlyError(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void limpiarLocal() {
    carrito = const CarritoModel(items: <CarritoItemModel>[], subtotal: 0, totalItems: 0);
    notifyListeners();
  }

  String _friendlyError(Object e) => e.toString().replaceFirst('Exception: ', '').trim();
}
