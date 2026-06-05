import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/admin/admin_productos_controller.dart';
import '../../../models/producto_admin_model.dart';
import 'widgets/producto_detalle_widgets.dart';

class AdminProductoDetallePage extends StatefulWidget {
  final int idProducto;

  const AdminProductoDetallePage({
    super.key,
    required this.idProducto,
  });

  @override
  State<AdminProductoDetallePage> createState() =>
      _AdminProductoDetallePageState();
}

class _AdminProductoDetallePageState extends State<AdminProductoDetallePage> {
  final AdminProductosController _controller = AdminProductosController();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController precioFinalController = TextEditingController();

  ProductoAdminModel? producto;

  bool loading = true;
  bool subiendo = false;
  bool esVisible = true;

  File? imagenSeleccionada;

  // 1 = foto principal, 2 = foto secundaria
  int slotSeleccionado = 1;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  ProductoImagenAdminModel? _imagenPorSlot(
    ProductoAdminModel p,
    int slot,
  ) {
    if (slot == 1 && p.imagenes.isNotEmpty) {
      return p.imagenes[0];
    }

    if (slot == 2 && p.imagenes.length > 1) {
      return p.imagenes[1];
    }

    return null;
  }

  void _setPrecioSegunSlot(ProductoAdminModel p, int slot) {
    final imagenExistente = _imagenPorSlot(p, slot);

    if (imagenExistente != null) {
      precioFinalController.text =
          imagenExistente.precioFinal.toStringAsFixed(2);
      return;
    }

    precioFinalController.text = p.precioFinal > 0
        ? p.precioFinal.toStringAsFixed(2)
        : p.precioVenta.toStringAsFixed(2);
  }

  Future<void> cargarDetalle() async {
    setState(() => loading = true);

    try {
      final detalle = await _controller.obtenerDetalleProducto(
        widget.idProducto,
      );

      if (!mounted) return;

      setState(() {
        producto = detalle;
        esVisible = detalle.activo ?? true;
        loading = false;
        _setPrecioSegunSlot(detalle, slotSeleccionado);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> tomarFoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        imagenSeleccionada = File(photo.path);
      });
    }
  }

  Future<void> elegirDeGaleria() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        imagenSeleccionada = File(photo.path);
      });
    }
  }

  void quitarImagenSeleccionada() {
    setState(() {
      imagenSeleccionada = null;
    });
  }

  double? _obtenerPrecioFinal() {
    final texto = precioFinalController.text.trim();

    if (texto.isEmpty) return null;

    final limpio = texto.replaceAll(',', '.');

    return double.tryParse(limpio);
  }

  Future<void> guardarCambiosImagenPrecio() async {
    final p = producto;

    if (p == null) return;

    final precioFinal = _obtenerPrecioFinal();

    if (precioFinal == null || precioFinal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Ingresa un precio final válido.'),
        ),
      );
      return;
    }

    final imagenExistente = _imagenPorSlot(p, slotSeleccionado);
    final ranuraOcupada = imagenExistente != null;

    if (!ranuraOcupada && imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Selecciona una imagen para esta ranura.'),
        ),
      );
      return;
    }

    if (!ranuraOcupada && p.totalImagenes >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Este producto ya tiene 2 fotos. Selecciona una ranura ocupada para cambiarla.',
          ),
        ),
      );
      return;
    }

    setState(() => subiendo = true);

    try {
      String msg;

      if (ranuraOcupada && imagenSeleccionada != null) {
        // Caso 1: ranura ocupada + imagen nueva = cambiar imagen y precio.
        msg = await _controller.cambiarImagenProducto(
          imagenId: imagenExistente.id,
          imagen: imagenSeleccionada!,
          precioFinal: precioFinal,
          esPrincipal: slotSeleccionado == 1,
        );
      } else if (ranuraOcupada && imagenSeleccionada == null) {
        // Caso 2: ranura ocupada + sin imagen nueva = solo editar precio final.
        msg = await _controller.actualizarPrecioFinalImagen(
          imagenId: imagenExistente.id,
          precioFinal: precioFinal,
        );
      } else {
        // Caso 3: ranura vacía + imagen nueva = subir nueva imagen.
        msg = await _controller.subirImagenProducto(
          idProducto: widget.idProducto,
          imagen: imagenSeleccionada!,
          precioFinal: precioFinal,
          esPrincipal: slotSeleccionado == 1,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(msg),
        ),
      );

      setState(() {
        imagenSeleccionada = null;
      });

      await cargarDetalle();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => subiendo = false);
      }
    }
  }

  Future<void> _toggleVisibilidad(bool value) async {
    setState(() => esVisible = value);

    try {
      final msg = await _controller.cambiarVisibilidadProducto(
        idProducto: widget.idProducto,
        esVisible: value,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text(msg),
        ),
      );
    } catch (e) {
      setState(() => esVisible = !value);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error al cambiar visibilidad.'),
        ),
      );
    }
  }

  void seleccionarSlot(int slot) {
    final p = producto;

    if (p == null) return;

    setState(() {
      slotSeleccionado = slot;
      imagenSeleccionada = null;
      _setPrecioSegunSlot(p, slot);
    });
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
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5E35B1)),
        ),
      );
    }

    final p = producto;

    if (p == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: Text('Producto no encontrado'),
        ),
      );
    }

    final imagenExistente = _imagenPorSlot(p, slotSeleccionado);
    final ranuraOcupada = imagenExistente != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: const Text(
          'Detalle del Producto',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductoAndroidHeader(producto: p),
            const SizedBox(height: 20),

            ProductoPhotoSlots(
              producto: p,
              slotSeleccionado: slotSeleccionado,
              imagenSeleccionada: imagenSeleccionada,
              onSelectSlot: seleccionarSlot,
            ),

            const SizedBox(height: 20),

            PrecioFinalEditorCard(
              controller: precioFinalController,
              precioVenta: p.precioVenta,
              enabled: !subiendo,
              ranuraOcupada: ranuraOcupada,
              tieneImagenNueva: imagenSeleccionada != null,
            ),

            const SizedBox(height: 20),

            ProductoInfoSection(producto: p),
            const SizedBox(height: 20),

            ProductoVisibilityCard(
              esVisible: esVisible,
              onChanged: _toggleVisibilidad,
            ),

            const SizedBox(height: 20),

            ProductoImageActions(
              subiendo: subiendo,
              totalImagenes: p.totalImagenes,
              slotSeleccionado: slotSeleccionado,
              ranuraOcupada: ranuraOcupada,
              tieneImagenSeleccionada: imagenSeleccionada != null,
              onTomarFoto: tomarFoto,
              onElegirGaleria: elegirDeGaleria,
              onQuitarImagenSeleccionada: quitarImagenSeleccionada,
              onGuardarCambios: guardarCambiosImagenPrecio,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}