import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/admin/admin_productos_controller.dart';
import '../../../models/producto_admin_model.dart';
import 'widgets/producto_detalle_widgets.dart';

const _adminPurple = Color(0xFF5E35B1);
const _adminText = Color(0xFF2C3E50);
const _adminBg = Color(0xFFF5F7FA);

class AdminProductoDetallePage extends StatefulWidget {
  final int idProducto;

  const AdminProductoDetallePage({super.key, required this.idProducto});

  @override
  State<AdminProductoDetallePage> createState() => _AdminProductoDetallePageState();
}

class _AdminProductoDetallePageState extends State<AdminProductoDetallePage> {
  final AdminProductosController _controller = AdminProductosController();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController precioFinalController = TextEditingController();

  ProductoAdminModel? producto;

  bool loading = true;
  bool subiendo = false;
  bool esVisible = true;
  bool huboCambios = false;

  XFile? imagenSlot1;
  XFile? imagenSlot2;
  Uint8List? imagenSlot1Bytes;
  Uint8List? imagenSlot2Bytes;
  String? imagenSlot1Nombre;
  String? imagenSlot2Nombre;

  // 1 = foto principal, 2 = foto secundaria
  int slotSeleccionado = 1;

  @override
  void initState() {
    super.initState();
    cargarDetalle(showSuccess: false);
  }

  ProductoImagenAdminModel? _imagenPorSlot(ProductoAdminModel p, int slot) {
    if (slot == 1 && p.imagenes.isNotEmpty) return p.imagenes[0];
    if (slot == 2 && p.imagenes.length > 1) return p.imagenes[1];
    return null;
  }

  int get _imagenesNuevasCount {
    int total = 0;
    if (imagenSlot1 != null) total++;
    if (imagenSlot2 != null) total++;
    return total;
  }

  XFile? _imagenSeleccionadaActual() => slotSeleccionado == 1 ? imagenSlot1 : imagenSlot2;

  void _setPrecioSegunSlot(ProductoAdminModel p, int slot) {
    final imagenExistente = _imagenPorSlot(p, slot);
    if (imagenExistente != null) {
      precioFinalController.text = imagenExistente.precioFinal.toStringAsFixed(2);
      return;
    }

    precioFinalController.text = p.precioFinal > 0
        ? p.precioFinal.toStringAsFixed(2)
        : p.precioVenta.toStringAsFixed(2);
  }

  Future<void> cargarDetalle({bool showSuccess = true}) async {
    setState(() => loading = true);

    try {
      final detalle = await _controller.obtenerDetalleProducto(widget.idProducto);

      if (!mounted) return;

      setState(() {
        producto = detalle;
        esVisible = detalle.activo ?? true;
        loading = false;
        _setPrecioSegunSlot(detalle, slotSeleccionado);
      });

      if (showSuccess) {
        _notify('Detalle actualizado correctamente.', type: _NoticeType.success);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _notify(e.toString().replaceFirst('Exception: ', ''), type: _NoticeType.error);
    }
  }

  Future<void> tomarFoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        await _registrarImagenEnSlot(
          slotSeleccionado,
          photo,
          'Foto agregada a la ranura $slotSeleccionado. Falta confirmar guardado.',
        );
      }
    } catch (_) {
      _notify('No se pudo abrir la cámara. En web usa Galería/Archivo.', type: _NoticeType.warning);
    }
  }

  Future<void> elegirDeGaleria() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (photo != null) {
        await _registrarImagenEnSlot(
          slotSeleccionado,
          photo,
          'Imagen agregada a la ranura $slotSeleccionado. Revisa precio final y confirma.',
        );
      }
    } catch (_) {
      _notify('No se pudo seleccionar la imagen.', type: _NoticeType.error);
    }
  }

  Future<void> elegirDosImagenesGaleria() async {
    try {
      final seleccionadas = await _picker.pickMultiImage(imageQuality: 80);

      if (seleccionadas.isEmpty) {
        _notify('No seleccionaste imágenes.', type: _NoticeType.info);
        return;
      }

      final primerasDos = seleccionadas.take(2).toList();

      if (primerasDos.length == 1) {
        await _registrarImagenEnSlot(
          slotSeleccionado,
          primerasDos.first,
          'Solo seleccionaste 1 imagen. Quedó en la ranura $slotSeleccionado.',
        );
        return;
      }

      await _registrarImagenEnSlot(1, primerasDos[0], 'Imagen 1 preparada.');
      await _registrarImagenEnSlot(2, primerasDos[1], 'Imagen 2 preparada.');

      if (!mounted) return;
      setState(() => slotSeleccionado = 1);

      final extra = seleccionadas.length > 2 ? ' Tomé solo las primeras 2.' : '';
      _notify('2 imágenes listas para subir con el mismo precio final.$extra', type: _NoticeType.success);
    } catch (_) {
      _notify('No se pudieron seleccionar las 2 imágenes.', type: _NoticeType.error);
    }
  }

  Future<void> _registrarImagenEnSlot(int slot, XFile photo, String mensaje) async {
    try {
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty) {
        _notify('La imagen seleccionada está vacía.', type: _NoticeType.warning);
        return;
      }

      const maxBytes = 8 * 1024 * 1024;
      if (bytes.length > maxBytes) {
        _notify('La imagen supera los 8 MB. Usa una imagen más liviana.', type: _NoticeType.warning);
        return;
      }

      final nombre = photo.name.isNotEmpty ? photo.name : 'imagen_producto_$slot.jpg';

      setState(() {
        if (slot == 1) {
          imagenSlot1 = photo;
          imagenSlot1Bytes = bytes;
          imagenSlot1Nombre = nombre;
        } else {
          imagenSlot2 = photo;
          imagenSlot2Bytes = bytes;
          imagenSlot2Nombre = nombre;
        }
      });

      if (mensaje.isNotEmpty) {
        _notify(mensaje, type: _NoticeType.info);
      }
    } catch (_) {
      _notify('No se pudo preparar la vista previa de la imagen.', type: _NoticeType.error);
    }
  }

  void quitarImagenSeleccionada() {
    setState(() {
      if (slotSeleccionado == 1) {
        imagenSlot1 = null;
        imagenSlot1Bytes = null;
        imagenSlot1Nombre = null;
      } else {
        imagenSlot2 = null;
        imagenSlot2Bytes = null;
        imagenSlot2Nombre = null;
      }
    });

    _notify('Selección de ranura $slotSeleccionado eliminada. No se cambió nada en el servidor.', type: _NoticeType.info);
  }

  void quitarTodasImagenesSeleccionadas() {
    setState(() {
      imagenSlot1 = null;
      imagenSlot2 = null;
      imagenSlot1Bytes = null;
      imagenSlot2Bytes = null;
      imagenSlot1Nombre = null;
      imagenSlot2Nombre = null;
    });

    _notify('Selecciones eliminadas. No se cambió nada en el servidor.', type: _NoticeType.info);
  }

  double? _obtenerPrecioFinal() {
    final texto = precioFinalController.text.trim();
    if (texto.isEmpty) return null;
    return double.tryParse(texto.replaceAll(',', '.'));
  }

  Future<void> guardarCambiosImagenPrecio() async {
    final p = producto;
    if (p == null || subiendo) return;

    final precioFinal = _obtenerPrecioFinal();
    if (precioFinal == null || precioFinal <= 0) {
      _notify('Ingresa un precio final válido.', type: _NoticeType.warning);
      return;
    }

    final imagenesNuevas = _imagenesNuevasCount;
    final imagenExistenteSlotActual = _imagenPorSlot(p, slotSeleccionado);
    final ranuraActualOcupada = imagenExistenteSlotActual != null;

    if (imagenesNuevas == 0 && !ranuraActualOcupada) {
      _notify('Selecciona una imagen para esta ranura antes de guardar.', type: _NoticeType.warning);
      return;
    }

    final title = imagenesNuevas >= 2
        ? 'Subir 2 imágenes'
        : imagenesNuevas == 1
            ? 'Guardar imagen seleccionada'
            : 'Actualizar precio final';

    final message = imagenesNuevas >= 2
        ? 'Se guardarán las 2 imágenes con precio final \$${precioFinal.toStringAsFixed(2)}. La ranura 1 será principal y la ranura 2 secundaria.'
        : imagenesNuevas == 1
            ? 'Se guardará la imagen seleccionada con precio final \$${precioFinal.toStringAsFixed(2)}.'
            : 'Se actualizará únicamente el precio final de la ranura $slotSeleccionado a \$${precioFinal.toStringAsFixed(2)}.';

    final okConfirm = await _confirm(
      title: title,
      message: '$message\n\n¿Confirmas la operación?',
      action: 'Confirmar',
      icon: imagenesNuevas >= 2 ? Icons.collections_rounded : Icons.verified_rounded,
    );

    if (!okConfirm) {
      _notify('Operación cancelada. Nada se envió al servidor.', type: _NoticeType.info);
      return;
    }

    setState(() => subiendo = true);

    try {
      String msg;

      if (imagenesNuevas > 0) {
        final mensajes = await _controller.guardarImagenesProducto(
          idProducto: widget.idProducto,
          precioFinal: precioFinal,
          imagenSlot1: imagenSlot1,
          imagenSlot2: imagenSlot2,
          imagenIdSlot1: _imagenPorSlot(p, 1)?.id,
          imagenIdSlot2: _imagenPorSlot(p, 2)?.id,
        );

        msg = imagenesNuevas >= 2
            ? '2 imágenes guardadas correctamente con precio final \$${precioFinal.toStringAsFixed(2)}.'
            : mensajes.isNotEmpty
                ? mensajes.last
                : 'Imagen guardada correctamente.';
      } else {
        final imagenParaActualizar = imagenExistenteSlotActual;
        if (imagenParaActualizar == null) {
          throw Exception('Selecciona una ranura con imagen para actualizar el precio final.');
        }

        msg = await _controller.actualizarPrecioFinalImagen(
          imagenId: imagenParaActualizar.id,
          precioFinal: precioFinal,
        );
      }

      if (!mounted) return;
      huboCambios = true;
      setState(() {
        imagenSlot1 = null;
        imagenSlot2 = null;
        imagenSlot1Bytes = null;
        imagenSlot2Bytes = null;
        imagenSlot1Nombre = null;
        imagenSlot2Nombre = null;
      });
      _notify(msg, type: _NoticeType.success);
      await cargarDetalle(showSuccess: false);
    } catch (e) {
      if (!mounted) return;
      _notify(e.toString().replaceFirst('Exception: ', ''), type: _NoticeType.error);
    } finally {
      if (mounted) setState(() => subiendo = false);
    }
  }

  Future<void> _toggleVisibilidad(bool value) async {
    if (subiendo) return;

    final okConfirm = await _confirm(
      title: value ? 'Mostrar producto' : 'Ocultar producto',
      message: value
          ? 'El producto volverá a mostrarse en el catálogo para clientes.'
          : 'El producto quedará oculto para clientes, pero seguirá disponible en administración.',
      action: value ? 'Mostrar' : 'Ocultar',
      icon: value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
    );

    if (!okConfirm) {
      _notify('Cambio de visibilidad cancelado.', type: _NoticeType.info);
      return;
    }

    setState(() => esVisible = value);

    try {
      final msg = await _controller.cambiarVisibilidadProducto(idProducto: widget.idProducto, esVisible: value);
      if (!mounted) return;
      huboCambios = true;
      _notify(msg, type: _NoticeType.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => esVisible = !value);
      _notify('Error al cambiar visibilidad. Se revirtió el cambio visual.', type: _NoticeType.error);
    }
  }

  void seleccionarSlot(int slot) {
    final p = producto;
    if (p == null) return;

    setState(() {
      slotSeleccionado = slot;
      _setPrecioSegunSlot(p, slot);
    });

    final imagenExistente = _imagenPorSlot(p, slot);
    _notify(
      imagenExistente == null
          ? 'Ranura $slot seleccionada. Lista para nueva imagen.'
          : 'Ranura $slot seleccionada. Puedes editar precio o reemplazar foto.',
      type: _NoticeType.info,
    );
  }

  Future<void> _confirmarActualizar() async {
    final ok = await _confirm(
      title: 'Actualizar detalle',
      message: 'Se volverá a consultar el producto para traer fotos, precio y visibilidad actualizados.',
      action: 'Actualizar',
      icon: Icons.refresh_rounded,
    );
    if (ok) await cargarDetalle();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _adminPurple.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: _adminPurple),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
              ],
            ),
            content: Text(message, style: const TextStyle(height: 1.45)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _adminPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _notify(String message, {required _NoticeType type}) {
    if (!mounted) return;
    final color = switch (type) {
      _NoticeType.success => Colors.green.shade700,
      _NoticeType.error => Colors.redAccent,
      _NoticeType.warning => Colors.orange.shade700,
      _NoticeType.info => _adminText,
    };
    final icon = switch (type) {
      _NoticeType.success => Icons.check_circle_rounded,
      _NoticeType.error => Icons.error_rounded,
      _NoticeType.warning => Icons.warning_amber_rounded,
      _NoticeType.info => Icons.info_rounded,
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    precioFinalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: _adminBg,
        body: Center(child: CircularProgressIndicator(color: _adminPurple)),
      );
    }

    final p = producto;
    if (p == null) {
      return const Scaffold(backgroundColor: _adminBg, body: Center(child: Text('Producto no encontrado')));
    }

    final imagenExistente = _imagenPorSlot(p, slotSeleccionado);
    final ranuraOcupada = imagenExistente != null;

    return Scaffold(
      backgroundColor: _adminBg,
      appBar: AppBar(
        backgroundColor: _adminBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _adminText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, huboCambios),
        ),
        title: const Text('Detalle del Producto', style: TextStyle(color: _adminText, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Actualizar detalle',
            onPressed: _confirmarActualizar,
            icon: const Icon(Icons.refresh_rounded, color: _adminPurple),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          final content = isWide ? _buildDesktop(p, ranuraOcupada) : _buildMobile(p, ranuraOcupada);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 10, isWide ? 28 : 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: content,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobile(ProductoAdminModel p, bool ranuraOcupada) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductoAndroidHeader(producto: p),
        const SizedBox(height: 20),
        ProductoPhotoSlots(
          producto: p,
          slotSeleccionado: slotSeleccionado,
          imagenSlot1Bytes: imagenSlot1Bytes,
          imagenSlot2Bytes: imagenSlot2Bytes,
          imagenSlot1Nombre: imagenSlot1Nombre,
          imagenSlot2Nombre: imagenSlot2Nombre,
          onSelectSlot: seleccionarSlot,
        ),
        const SizedBox(height: 20),
        _editorStack(p, ranuraOcupada),
      ],
    );
  }

  Widget _buildDesktop(ProductoAdminModel p, bool ranuraOcupada) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductoAndroidHeader(producto: p),
              const SizedBox(height: 20),
              ProductoPhotoSlots(
                producto: p,
                slotSeleccionado: slotSeleccionado,
                imagenSlot1Bytes: imagenSlot1Bytes,
                imagenSlot2Bytes: imagenSlot2Bytes,
                imagenSlot1Nombre: imagenSlot1Nombre,
                imagenSlot2Nombre: imagenSlot2Nombre,
                onSelectSlot: seleccionarSlot,
              ),
              const SizedBox(height: 20),
              ProductoInfoSection(producto: p),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(flex: 4, child: _editorStack(p, ranuraOcupada, includeInfo: false)),
      ],
    );
  }

  Widget _editorStack(ProductoAdminModel p, bool ranuraOcupada, {bool includeInfo = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (includeInfo) ...[
          ProductoInfoSection(producto: p),
          const SizedBox(height: 20),
        ],
        PrecioFinalEditorCard(
          controller: precioFinalController,
          precioVenta: p.precioVenta,
          enabled: !subiendo,
          ranuraOcupada: ranuraOcupada,
          imagenesNuevasCount: _imagenesNuevasCount,
        ),
        const SizedBox(height: 20),
        ProductoVisibilityCard(esVisible: esVisible, onChanged: _toggleVisibilidad),
        const SizedBox(height: 20),
        ProductoImageActions(
          subiendo: subiendo,
          totalImagenes: p.totalImagenes,
          slotSeleccionado: slotSeleccionado,
          ranuraOcupada: ranuraOcupada,
          imagenesNuevasCount: _imagenesNuevasCount,
          onTomarFoto: tomarFoto,
          onElegirGaleria: elegirDeGaleria,
          onElegirDosImagenes: elegirDosImagenesGaleria,
          onQuitarImagenSeleccionada: quitarImagenSeleccionada,
          onQuitarTodasImagenes: quitarTodasImagenesSeleccionadas,
          onGuardarCambios: guardarCambiosImagenPrecio,
        ),
      ],
    );
  }
}

enum _NoticeType { success, error, warning, info }
