import 'package:image_picker/image_picker.dart';

import '../../models/producto_admin_model.dart';
import '../../services/admin_productos_service.dart';

class AdminProductosController {
  final AdminProductosService _service = AdminProductosService();

  Future<List<ProductoAdminModel>> obtenerProductos() async {
    final data = await _service.obtenerProductosAdmin();

    return data
        .where((e) => e is Map)
        .map<ProductoAdminModel>(
          (e) => ProductoAdminModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<ProductoAdminModel> obtenerDetalleProducto(int idProducto) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    final data = await _service.obtenerDetalleProducto(idProducto);

    return ProductoAdminModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<String> subirImagenProducto({
    required int idProducto,
    required XFile imagen,
    double? precioFinal,
    bool? esPrincipal,
  }) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    await _validarImagen(imagen);
    _validarPrecio(precioFinal);

    final data = await _service.subirImagenProducto(
      idProducto: idProducto,
      imagen: imagen,
      precioFinal: precioFinal,
      esPrincipal: esPrincipal,
    );

    return data['message']?.toString() ?? 'Imagen guardada correctamente.';
  }

  Future<String> cambiarImagenProducto({
    required int imagenId,
    required XFile imagen,
    double? precioFinal,
    bool? esPrincipal,
  }) async {
    if (imagenId <= 0) {
      throw Exception('ID de imagen inválido.');
    }

    await _validarImagen(imagen);
    _validarPrecio(precioFinal);

    final data = await _service.cambiarImagenProducto(
      imagenId: imagenId,
      imagen: imagen,
      precioFinal: precioFinal,
      esPrincipal: esPrincipal,
    );

    return data['message']?.toString() ?? 'Imagen reemplazada correctamente.';
  }

  /// Guarda una o dos imágenes en una sola acción de UI.
  ///
  /// Nota operativa: el backend actual recibe una imagen por endpoint. Por eso
  /// este método hace las operaciones secuenciales bajo una misma confirmación:
  /// - si la ranura tiene imagenId, reemplaza esa imagen;
  /// - si la ranura no tiene imagenId, crea una nueva imagen para el producto.
  ///
  /// El precio final se envía igual para ambas imágenes, tal como se solicita en
  /// la vista administrativa.
  Future<List<String>> guardarImagenesProducto({
    required int idProducto,
    required double precioFinal,
    XFile? imagenSlot1,
    XFile? imagenSlot2,
    int? imagenIdSlot1,
    int? imagenIdSlot2,
  }) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    _validarPrecio(precioFinal);

    final operaciones = <Future<String> Function()>[];

    if (imagenSlot1 != null) {
      await _validarImagen(imagenSlot1);
      operaciones.add(() {
        if (imagenIdSlot1 != null && imagenIdSlot1 > 0) {
          return cambiarImagenProducto(
            imagenId: imagenIdSlot1,
            imagen: imagenSlot1,
            precioFinal: precioFinal,
            esPrincipal: true,
          );
        }

        return subirImagenProducto(
          idProducto: idProducto,
          imagen: imagenSlot1,
          precioFinal: precioFinal,
          esPrincipal: true,
        );
      });
    }

    if (imagenSlot2 != null) {
      await _validarImagen(imagenSlot2);
      operaciones.add(() {
        if (imagenIdSlot2 != null && imagenIdSlot2 > 0) {
          return cambiarImagenProducto(
            imagenId: imagenIdSlot2,
            imagen: imagenSlot2,
            precioFinal: precioFinal,
            esPrincipal: false,
          );
        }

        return subirImagenProducto(
          idProducto: idProducto,
          imagen: imagenSlot2,
          precioFinal: precioFinal,
          esPrincipal: false,
        );
      });
    }

    if (operaciones.isEmpty) {
      throw Exception('Selecciona al menos una imagen para guardar.');
    }

    final mensajes = <String>[];
    for (final operacion in operaciones) {
      mensajes.add(await operacion());
    }

    return mensajes;
  }

  Future<String> actualizarPrecioFinalImagen({
    required int imagenId,
    required double precioFinal,
  }) async {
    if (imagenId <= 0) {
      throw Exception('ID de imagen inválido.');
    }

    _validarPrecio(precioFinal);

    final data = await _service.actualizarPrecioFinalImagen(
      imagenId: imagenId,
      precioFinal: precioFinal,
    );

    return data['message']?.toString() ??
        'Precio final actualizado correctamente.';
  }

  Future<String> cambiarVisibilidadProducto({
    required int idProducto,
    required bool esVisible,
  }) async {
    if (idProducto <= 0) {
      throw Exception('ID de producto inválido.');
    }

    return await _service.cambiarEstadoProducto(
      idProducto: idProducto,
      activo: esVisible,
    );
  }

  Future<void> _validarImagen(XFile imagen) async {
    final bytes = await imagen.readAsBytes();

    if (bytes.isEmpty) {
      throw Exception('La imagen seleccionada está vacía.');
    }

    const maxBytes = 8 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw Exception('La imagen supera los 8 MB. Usa una imagen más liviana.');
    }
  }

  void _validarPrecio(double? precioFinal) {
    if (precioFinal != null && precioFinal < 0) {
      throw Exception('El precio final no puede ser negativo.');
    }
  }
}
