import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/novedad_model.dart';
import '../../../../models/novedad_producto_imagen_model.dart';
import 'admin_novedades_widgets.dart';
import 'novedades_web_safe_network_image.dart';

typedef NovedadSubmit = Future<bool> Function({
  required String titulo,
  required String descripcion,
  XFile? foto,
  int? productoImagenId,
  String? enlaceUrl,
  required bool activo,
  required int orden,
});

typedef BuscarProductosParaNovedad = Future<List<ProductoNovedadBusquedaModel>> Function(String nombre);

class NovedadFormSheet extends StatefulWidget {
  final NovedadModel? novedad;
  final NovedadSubmit onSubmit;
  final BuscarProductosParaNovedad onBuscarProductos;

  const NovedadFormSheet({
    super.key,
    this.novedad,
    required this.onSubmit,
    required this.onBuscarProductos,
  });

  @override
  State<NovedadFormSheet> createState() => _NovedadFormSheetState();
}

class _NovedadFormSheetState extends State<NovedadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _productoNombreCtrl = TextEditingController();
  final _enlaceCtrl = TextEditingController();
  final _ordenCtrl = TextEditingController();

  XFile? _foto;
  Uint8List? _fotoBytes;
  bool _activo = true;
  bool _savingLocal = false;
  bool _buscandoProducto = false;
  String? _errorBusqueda;

  List<ProductoNovedadBusquedaModel> _productosEncontrados = [];
  ProductoImagenNovedadOption? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    final n = widget.novedad;
    _tituloCtrl.text = n?.titulo ?? '';
    _descripcionCtrl.text = n?.descripcion ?? '';
    _enlaceCtrl.text = n?.enlaceUrl ?? '';
    _ordenCtrl.text = (n?.orden ?? 1).toString();
    _activo = n?.activo ?? true;

    if (n?.productoImagenId != null) {
      _imagenSeleccionada = ProductoImagenNovedadOption.soloId(n!.productoImagenId!);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _productoNombreCtrl.dispose();
    _enlaceCtrl.dispose();
    _ordenCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagenLocal() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      _foto = picked;
      _fotoBytes = bytes;
    });

    _notice('Imagen local seleccionada. Falta guardar para enviarla al servidor.');
  }

  void _quitarFotoLocal() {
    setState(() {
      _foto = null;
      _fotoBytes = null;
    });
    _notice('Selección local quitada.');
  }

  Future<void> _buscarProductoPorNombre() async {
    final query = _productoNombreCtrl.text.trim();

    if (query.length < 2) {
      setState(() => _errorBusqueda = 'Ingresá al menos 2 letras del producto.');
      return;
    }

    setState(() {
      _buscandoProducto = true;
      _errorBusqueda = null;
      _productosEncontrados = [];
    });

    try {
      final productos = await widget.onBuscarProductos(query);
      if (!mounted) return;
      setState(() => _productosEncontrados = productos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBusqueda = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _buscandoProducto = false);
    }
  }

  void _limpiarImagenProducto() {
    setState(() {
      _productosEncontrados = [];
      _imagenSeleccionada = null;
      _productoNombreCtrl.clear();
      _errorBusqueda = null;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final orden = int.tryParse(_ordenCtrl.text.trim()) ?? 0;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(widget.novedad == null ? 'Crear novedad' : 'Actualizar novedad', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          _foto != null
              ? 'Se guardará la novedad con una imagen local nueva. ¿Continuamos con la jugada?'
              : 'Se guardará la novedad sin subir archivo nuevo. ¿Confirmamos operación?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kNovedadPink, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _savingLocal = true);

    final ok = await widget.onSubmit(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      foto: _foto,
      productoImagenId: _imagenSeleccionada?.id,
      enlaceUrl: _enlaceCtrl.text.trim().isEmpty ? null : _enlaceCtrl.text.trim(),
      activo: _activo,
      orden: orden,
    );

    if (!mounted) return;
    setState(() => _savingLocal = false);

    if (ok) Navigator.pop(context, true);
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kNovedadText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.novedad != null;
    final maxWidth = MediaQuery.of(context).size.width >= 900 ? 920.0 : double.infinity;

    return DraggableScrollableSheet(
      initialChildSize: MediaQuery.of(context).size.width >= 900 ? 0.88 : 0.94,
      minChildSize: 0.55,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kNovedadBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 54,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              editando ? 'Editar novedad' : 'Nueva novedad',
                              style: const TextStyle(color: kNovedadText, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                          IconButton.filledTonal(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      NovedadImagePickerBox(
                        pickedBytes: _fotoBytes,
                        imageUrl: widget.novedad?.imagenPrincipal ?? '',
                        onPick: _seleccionarImagenLocal,
                        onClearLocal: _foto == null ? null : _quitarFotoLocal,
                      ),
                      const SizedBox(height: 16),
                      ProductoImagenSelector(
                        productoNombreController: _productoNombreCtrl,
                        buscando: _buscandoProducto,
                        error: _errorBusqueda,
                        productos: _productosEncontrados,
                        imagenSeleccionada: _imagenSeleccionada,
                        onBuscar: _buscarProductoPorNombre,
                        onLimpiar: _limpiarImagenProducto,
                        onSeleccionarImagen: (imagen) {
                          setState(() => _imagenSeleccionada = imagen);
                          _notice('Imagen de producto #${imagen.id} vinculada a la novedad.');
                        },
                      ),
                      const SizedBox(height: 16),
                      _InputCard(
                        child: TextFormField(
                          controller: _tituloCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Título', border: InputBorder.none, prefixIcon: Icon(Icons.title_rounded)),
                          validator: (value) => (value ?? '').trim().isEmpty ? 'El título es obligatorio.' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InputCard(
                        child: TextFormField(
                          controller: _descripcionCtrl,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'Descripción', border: InputBorder.none, prefixIcon: Icon(Icons.notes_rounded)),
                          validator: (value) => (value ?? '').trim().isEmpty ? 'La descripción es obligatoria.' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InputCard(
                        child: TextFormField(
                          controller: _enlaceCtrl,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(labelText: 'Enlace URL opcional', border: InputBorder.none, prefixIcon: Icon(Icons.link_rounded)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InputCard(
                              child: TextFormField(
                                controller: _ordenCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Orden', border: InputBorder.none, prefixIcon: Icon(Icons.format_list_numbered_rounded)),
                                validator: (value) {
                                  final orden = int.tryParse((value ?? '').trim());
                                  if (orden == null) return 'Orden inválido.';
                                  if (orden < 0) return 'No puede ser negativo.';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
                              child: Row(
                                children: [
                                  const Expanded(child: Text('Visible', style: TextStyle(fontWeight: FontWeight.w900, color: kNovedadText))),
                                  Switch(value: _activo, activeColor: kNovedadPink, onChanged: (value) => setState(() => _activo = value)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _savingLocal ? null : _guardar,
                          icon: _savingLocal
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded),
                          label: Text(_savingLocal ? 'Guardando...' : (editando ? 'Actualizar novedad' : 'Crear novedad'), style: const TextStyle(fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNovedadPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NovedadImagePickerBox extends StatelessWidget {
  final Uint8List? pickedBytes;
  final String imageUrl;
  final VoidCallback onPick;
  final VoidCallback? onClearLocal;

  const NovedadImagePickerBox({
    super.key,
    required this.pickedBytes,
    required this.imageUrl,
    required this.onPick,
    required this.onClearLocal,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();
    final hasImage = pickedBytes != null || cleanUrl.isNotEmpty;

    Widget content;
    if (pickedBytes != null) {
      content = Image.memory(pickedBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.contain);
    } else if (cleanUrl.isNotEmpty && cleanUrl.toLowerCase() != 'null') {
      content = NovedadesWebSafeNetworkImage(
        url: cleanUrl,
        fit: BoxFit.contain,
        errorWidget: const _ImagePlaceholder(),
      );
    } else {
      content = const _ImagePlaceholder();
    }

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 290,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(padding: const EdgeInsets.all(10), child: content),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.62), borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    pickedBytes != null ? 'Imagen local nueva' : (hasImage ? 'Imagen actual' : 'Sin imagen'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (onClearLocal != null)
                      _OverlayButton(icon: Icons.close_rounded, text: 'Quitar', onTap: onClearLocal!),
                    _OverlayButton(icon: Icons.upload_file_rounded, text: 'Elegir imagen', onTap: onPick),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductoImagenSelector extends StatelessWidget {
  final TextEditingController productoNombreController;
  final bool buscando;
  final String? error;
  final List<ProductoNovedadBusquedaModel> productos;
  final ProductoImagenNovedadOption? imagenSeleccionada;
  final VoidCallback onBuscar;
  final VoidCallback onLimpiar;
  final ValueChanged<ProductoImagenNovedadOption> onSeleccionarImagen;

  const ProductoImagenSelector({
    super.key,
    required this.productoNombreController,
    required this.buscando,
    required this.error,
    required this.productos,
    required this.imagenSeleccionada,
    required this.onBuscar,
    required this.onLimpiar,
    required this.onSeleccionarImagen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kNovedadPink.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: kNovedadPink),
              SizedBox(width: 8),
              Expanded(child: Text('Vincular imagen de producto', style: TextStyle(color: kNovedadText, fontWeight: FontWeight.w900, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Busca un producto y selecciona una imagen existente. Esto evita subir archivos duplicados.', style: TextStyle(color: Colors.grey.shade600, height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: productoNombreController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onBuscar(),
                  decoration: InputDecoration(
                    hintText: 'Nombre del producto...',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: buscando ? null : onBuscar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: buscando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ],
          if (imagenSeleccionada != null && productos.isEmpty) ...[
            const SizedBox(height: 12),
            _SelectedExistingImageBadge(imagenId: imagenSeleccionada!.id, onClear: onLimpiar),
          ],
          if (productos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('${productos.length} producto(s) encontrado(s)', style: const TextStyle(color: kNovedadText, fontWeight: FontWeight.w900, fontSize: 15))),
                TextButton.icon(onPressed: onLimpiar, icon: const Icon(Icons.close_rounded, size: 16), label: const Text('Limpiar')),
              ],
            ),
            const SizedBox(height: 10),
            ...productos.map((producto) {
              final imagenes = producto.imagenes.take(2).toList();
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFDFBFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kNovedadText, fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imagenes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final imagen = imagenes[index];
                          return ProductoImagenOptionCard(
                            imagen: imagen,
                            selected: imagenSeleccionada?.id == imagen.id,
                            onTap: () => onSeleccionarImagen(imagen),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class ProductoImagenOptionCard extends StatelessWidget {
  final ProductoImagenNovedadOption imagen;
  final bool selected;
  final VoidCallback onTap;

  const ProductoImagenOptionCard({super.key, required this.imagen, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 205,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? kNovedadPink : Colors.grey.shade200, width: selected ? 2 : 1),
          boxShadow: [BoxShadow(color: selected ? kNovedadPink.withOpacity(0.18) : Colors.black.withOpacity(0.04), blurRadius: selected ? 14 : 8, offset: const Offset(0, 5))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: NovedadesWebSafeNetworkImage(
                url: imagen.imagenUrl,
                fit: BoxFit.contain,
                errorWidget: const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),
            Positioned(left: 8, top: 8, child: _MiniDarkBadge(text: '#${imagen.id}')),
            Positioned(right: 8, top: 8, child: Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: selected ? kNovedadPink : Colors.black45)),
            if (imagen.esPrincipal) const Positioned(left: 8, bottom: 8, child: _PrincipalBadge()),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
      child: child,
    );
  }
}

class _SelectedExistingImageBadge extends StatelessWidget {
  final int imagenId;
  final VoidCallback onClear;

  const _SelectedExistingImageBadge({required this.imagenId, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kNovedadPurple.withOpacity(0.09), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: kNovedadPurple),
          const SizedBox(width: 8),
          Expanded(child: Text('Imagen vinculada actual: #$imagenId', style: const TextStyle(color: kNovedadPurple, fontWeight: FontWeight.w900))),
          IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded, color: kNovedadPurple)),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade400, size: 58),
            const SizedBox(height: 8),
            Text('Elegir imagen', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _OverlayButton({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.70), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MiniDarkBadge extends StatelessWidget {
  final String text;
  const _MiniDarkBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.62), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _PrincipalBadge extends StatelessWidget {
  const _PrincipalBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: kNovedadPink, borderRadius: BorderRadius.circular(99)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text('Principal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
      ),
    );
  }
}
