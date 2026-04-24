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

  ProductoAdminModel? producto;
  bool loading = true;
  bool subiendo = false;
  File? imagenSeleccionada;
  bool esVisible = true;

  @override
  void initState() {
    super.initState();
    cargarDetalle();
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
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

  Future<void> subirImagen() async {
    if (imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen primero')),
      );
      return;
    }

    setState(() => subiendo = true);

    try {
      final msg = await _controller.subirImagenProducto(
        idProducto: widget.idProducto,
        imagen: imagenSeleccionada!,
      );

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
          content: Text('Error al cambiar visibilidad'),
        ),
      );
    }
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
            ProductoImagePreview(
              imagenSeleccionada: imagenSeleccionada,
              imagenUrl: p.imagenUrl,
            ),
            const SizedBox(height: 24),

            ProductoInfoSection(producto: p),
            const SizedBox(height: 30),

            ProductoVisibilityCard(
              esVisible: esVisible,
              onChanged: _toggleVisibilidad,
            ),
            const SizedBox(height: 30),

            ProductoImageActions(
              subiendo: subiendo,
              onTomarFoto: tomarFoto,
              onElegirGaleria: elegirDeGaleria,
              onSubirImagen: subirImagen,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}