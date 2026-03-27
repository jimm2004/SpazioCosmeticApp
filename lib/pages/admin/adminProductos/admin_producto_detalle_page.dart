import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/admin/admin_productos_controller.dart';
import '../../../models/producto_admin_model.dart';

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
  
  // Variable para manejar la visibilidad en el catálogo
  bool esVisible = true; 

  @override
  void initState() {
    super.initState();
    cargarDetalle();
  }

  Future<void> cargarDetalle() async {
    setState(() => loading = true);

    try {
      final detalle = await _controller.obtenerDetalleProducto(widget.idProducto);

      setState(() {
        producto = detalle;
        // Ahora lee el estado real de visibilidad de tu base de datos
        esVisible = detalle.activo ?? true; 
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
        SnackBar(backgroundColor: Colors.green, content: Text(msg)),
      );

      setState(() {
        imagenSeleccionada = null;
      });

      await cargarDetalle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => subiendo = false);
    }
  }

  // MÉTODO PARA CAMBIAR VISIBILIDAD
  Future<void> _toggleVisibilidad(bool value) async {
    // Cambiamos visualmente primero para que sea rápido (optimistic update)
    setState(() => esVisible = value); 
    
    try {
      final msg = await _controller.cambiarVisibilidadProducto(
        idProducto: widget.idProducto, 
        esVisible: value
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.black87, content: Text(msg)),
      );
    } catch (e) {
      // Si falla, regresamos el switch a como estaba
      setState(() => esVisible = !value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.redAccent, content: Text('Error al cambiar visibilidad')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF5E35B1))),
      );
    }

    final p = producto!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: const Text(
          'Detalle del Producto',
          style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------
            // CONTENEDOR DE LA IMAGEN (TIPO HERO)
            // ------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: imagenSeleccionada != null
                    ? Image.file(
                        imagenSeleccionada!,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : p.imagenUrl != null && p.imagenUrl!.isNotEmpty
                        ? Image.network(
                            p.imagenUrl!,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _placeholder(),
                          )
                        : _placeholder(),
              ),
            ),
            
            const SizedBox(height: 24),

            // ------------------------------------
            // INFORMACIÓN DEL PRODUCTO
            // ------------------------------------
            Text(
              p.nombre,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Precio: \$${p.precioVenta.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              p.descripcion.isEmpty ? 'Este producto no tiene descripción.' : p.descripcion,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
            ),

            const SizedBox(height: 30),

            // ------------------------------------
            // OPCIONES DE CONFIGURACIÓN (SWITCH)
            // ------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: esVisible ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          esVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: esVisible ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visible en Catálogo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            esVisible ? 'Los clientes pueden verlo' : 'Oculto para clientes',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: esVisible,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: _toggleVisibilidad,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ------------------------------------
            // ACCIONES DE IMAGEN
            // ------------------------------------
            const Text(
              'Actualizar Fotografía',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: tomarFoto,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Cámara'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF5E35B1),
                      side: const BorderSide(color: Color(0xFF5E35B1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: elegirDeGaleria,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Galería'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF5E35B1),
                      side: const BorderSide(color: Color(0xFF5E35B1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: subiendo ? null : subirImagen,
                icon: subiendo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  subiendo ? 'Subiendo imagen...' : 'Guardar nueva imagen',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E35B1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 280,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sin imagen',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}