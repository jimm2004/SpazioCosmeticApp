import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/admin/admin_novedades_controller.dart';
import '../../../models/novedad_model.dart';
import '../../../models/novedad_producto_imagen_model.dart';

typedef NovedadSubmit = Future<bool> Function({
  required String titulo,
  required String descripcion,
  File? foto,
  int? productoImagenId,
  String? enlaceUrl,
  required bool activo,
  required int orden,
});

typedef BuscarProductosParaNovedad = Future<List<ProductoNovedadBusquedaModel>>
    Function(String nombre);


void _openImagePreview(
  BuildContext context, {
  File? file,
  String? imageUrl,
  String title = 'Vista completa',
}) {
  final hasFile = file != null;
  final hasUrl = imageUrl != null &&
      imageUrl.trim().isNotEmpty &&
      imageUrl.trim().toLowerCase() != 'null';

  if (!hasFile && !hasUrl) return;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.90),
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.all(14),
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.78,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      color: Colors.black,
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Center(
                          child: hasFile
                              ? Image.file(
                                  file,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                )
                              : Image.network(
                                  imageUrl!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) => const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white70,
                                      size: 72,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AdminNovedadesPage extends StatefulWidget {
  const AdminNovedadesPage({super.key});

  @override
  State<AdminNovedadesPage> createState() => _AdminNovedadesPageState();
}

class _AdminNovedadesPageState extends State<AdminNovedadesPage> {
  final AdminNovedadesController _controller = AdminNovedadesController();
  final TextEditingController _buscarNovedadCtrl = TextEditingController();

  String _filtroNovedad = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChange);
    _controller.cargarNovedades();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _buscarNovedadCtrl.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  List<NovedadModel> get _novedadesFiltradas {
    final query = _filtroNovedad.trim().toLowerCase();

    if (query.isEmpty) return _controller.novedades;

    return _controller.novedades.where((novedad) {
      final titulo = novedad.titulo.toLowerCase();
      final descripcion = novedad.descripcion.toLowerCase();
      return titulo.contains(query) || descripcion.contains(query);
    }).toList();
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.redAccent : const Color(0xFF00A86B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirFormulario({NovedadModel? novedad}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NovedadFormSheet(
        novedad: novedad,
        onBuscarProductos: _controller.buscarProductosParaNovedad,
        onSubmit: ({
          required String titulo,
          required String descripcion,
          File? foto,
          int? productoImagenId,
          String? enlaceUrl,
          required bool activo,
          required int orden,
        }) {
          if (novedad == null) {
            return _controller.crearNovedad(
              titulo: titulo,
              descripcion: descripcion,
              foto: foto,
              productoImagenId: productoImagenId,
              enlaceUrl: enlaceUrl,
              activo: activo,
              orden: orden,
            );
          }

          return _controller.actualizarNovedad(
            idNovedad: novedad.idNovedad,
            titulo: titulo,
            descripcion: descripcion,
            foto: foto,
            productoImagenId: productoImagenId,
            enlaceUrl: enlaceUrl,
            activo: activo,
            orden: orden,
          );
        },
      ),
    );

    if (ok == true) {
      _showSnack(
        novedad == null
            ? 'Novedad creada correctamente'
            : 'Novedad actualizada correctamente',
      );
    } else if (_controller.error != null) {
      _showSnack(_controller.error!, error: true);
    }
  }

  Future<void> _confirmarEliminar(
    NovedadModel novedad, {
    bool desdeDesactivar = false,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          desdeDesactivar ? 'Desactivar y eliminar' : 'Eliminar novedad',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          desdeDesactivar
              ? 'Al desactivar "${novedad.titulo}" se eliminará definitivamente. ¿Deseas continuar?'
              : '¿Seguro que deseas eliminar "${novedad.titulo}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(desdeDesactivar ? 'Sí, eliminar' : 'Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await _controller.eliminarNovedad(novedad);

    if (ok) {
      _showSnack(
        desdeDesactivar
            ? 'Novedad desactivada y eliminada'
            : 'Novedad eliminada',
      );
    } else {
      _showSnack(_controller.error ?? 'No se pudo eliminar', error: true);
    }
  }

  Future<void> _cambiarEstado(NovedadModel novedad, bool value) async {
    if (!value) {
      await _confirmarEliminar(novedad, desdeDesactivar: true);
      return;
    }

    final ok = await _controller.cambiarEstado(novedad, true);

    if (ok) {
      _showSnack('Novedad visible en catálogo');
    } else {
      _showSnack(_controller.error ?? 'No se pudo cambiar el estado',
          error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final novedadesFiltradas = _novedadesFiltradas;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Novedades',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _controller.loading ? null : _controller.cargarNovedades,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _controller.saving ? null : () => _abrirFormulario(),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text(
          'Nueva novedad',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE91E63),
        onRefresh: _controller.cargarNovedades,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: _HeaderCard(
                  total: _controller.novedades.length,
                  activas: _controller.novedades.where((n) => n.activo).length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _NovedadSearchBar(
                  controller: _buscarNovedadCtrl,
                  onChanged: (value) {
                    setState(() => _filtroNovedad = value);
                  },
                  onClear: () {
                    _buscarNovedadCtrl.clear();
                    setState(() => _filtroNovedad = '');
                  },
                ),
              ),
            ),
            if (_controller.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                ),
              )
            else if (_controller.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _ErrorState(
                      message: _controller.error!,
                      onRetry: _controller.cargarNovedades,
                    ),
                  ),
                ),
              )
            else if (_controller.novedades.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _EmptyState(onCreate: () => _abrirFormulario()),
                  ),
                ),
              )
            else if (novedadesFiltradas.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _NoSearchResults(
                      filtro: _filtroNovedad,
                      onClear: () {
                        _buscarNovedadCtrl.clear();
                        setState(() => _filtroNovedad = '');
                      },
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: novedadesFiltradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final novedad = novedadesFiltradas[index];

                    return _NovedadCard(
                      novedad: novedad,
                      onEdit: () => _abrirFormulario(novedad: novedad),
                      onDelete: () => _confirmarEliminar(novedad),
                      onToggle: (value) => _cambiarEstado(novedad, value),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;
  final int activas;

  const _HeaderCard({required this.total, required this.activas});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF15172B), Color(0xFF5E35B1), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -22,
            child: Icon(
              Icons.campaign_rounded,
              color: Colors.white.withAlpha(24),
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Centro de novedades',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea publicaciones y enlaza imágenes buscando productos por nombre.',
                style: TextStyle(
                  color: Colors.white.withAlpha(215),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniMetric(icon: Icons.list_alt_rounded, value: '$total', label: 'Total'),
                  _MiniMetric(icon: Icons.visibility_rounded, value: '$activas', label: 'Activas'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniMetric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(42),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            '$value $label',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NovedadSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _NovedadSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar novedad por nombre...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _NovedadCard extends StatelessWidget {
  final NovedadModel novedad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _NovedadCard({
    required this.novedad,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = novedad.imagenPrincipal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: novedad.activo
              ? const Color(0xFFE91E63).withAlpha(40)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: GestureDetector(
              onTap: imageUrl.isEmpty
                  ? null
                  : () => _openImagePreview(
                        context,
                        imageUrl: imageUrl,
                        title: novedad.titulo,
                      ),
              child: Container(
                height: 240,
                width: double.infinity,
                color: Colors.white,
                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 58,
                          color: Colors.grey,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 58,
                                  color: Colors.grey,
                                ),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE91E63),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_out_map_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Ver completa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(activo: novedad.activo),
                    const SizedBox(width: 8),
                    _OrderBadge(orden: novedad.orden),
                    const Spacer(),
                    Switch(
                      value: novedad.activo,
                      activeColor: const Color(0xFFE91E63),
                      onChanged: onToggle,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  novedad.titulo,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  novedad.descripcion,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35, fontWeight: FontWeight.w500),
                ),
                if (novedad.productoImagenId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Imagen de producto seleccionada: #${novedad.productoImagenId}',
                    style: const TextStyle(
                      color: Color(0xFF5E35B1),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5E35B1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Eliminar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool activo;
  const _StatusBadge({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? const Color(0xFF00A86B) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(99)),
      child: Text(
        activo ? 'Visible' : 'Oculta',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  final int orden;
  const _OrderBadge({required this.orden});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFE91E63).withAlpha(18), borderRadius: BorderRadius.circular(99)),
      child: Text(
        'Orden $orden',
        style: const TextStyle(color: Color(0xFFE91E63), fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _NovedadFormSheet extends StatefulWidget {
  final NovedadModel? novedad;
  final NovedadSubmit onSubmit;
  final BuscarProductosParaNovedad onBuscarProductos;

  const _NovedadFormSheet({
    this.novedad,
    required this.onSubmit,
    required this.onBuscarProductos,
  });

  @override
  State<_NovedadFormSheet> createState() => _NovedadFormSheetState();
}

class _NovedadFormSheetState extends State<_NovedadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _productoNombreCtrl = TextEditingController();
  final _enlaceCtrl = TextEditingController();
  final _ordenCtrl = TextEditingController();

  File? _foto;
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
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (picked == null) return;

    setState(() {
      _foto = File(picked.path);
    });
  }

  Future<void> _buscarProductoPorNombre() async {
    final query = _productoNombreCtrl.text.trim();

    if (query.length < 2) {
      setState(() {
        _errorBusqueda = 'Ingresá al menos 2 letras del producto.';
      });
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

      setState(() {
        _productosEncontrados = productos;
        if (productos.isNotEmpty && productos.first.imagenes.isNotEmpty) {
          _imagenSeleccionada = productos.first.imagenes.first;
        } else {
          _imagenSeleccionada = null;
          _errorBusqueda = 'No hay imágenes para seleccionar.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorBusqueda = e.toString().replaceFirst('Exception: ', '');
      });
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

    final orden = int.tryParse(_ordenCtrl.text.trim()) ?? 1;

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

  @override
  Widget build(BuildContext context) {
    final editando = widget.novedad != null;
    final imageUrl = widget.novedad?.imagenPrincipal ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.55,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).viewInsets.bottom + 26,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          editando ? 'Editar novedad' : 'Nueva novedad',
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ImagePickerBox(
                    foto: _foto,
                    imageUrl: imageUrl,
                    onPick: _seleccionarImagenLocal,
                  ),
                  const SizedBox(height: 12),
                  _ProductoImagenSelector(
                    productoNombreController: _productoNombreCtrl,
                    buscando: _buscandoProducto,
                    error: _errorBusqueda,
                    productos: _productosEncontrados,
                    imagenSeleccionada: _imagenSeleccionada,
                    onBuscar: _buscarProductoPorNombre,
                    onLimpiar: _limpiarImagenProducto,
                    onSeleccionarImagen: (imagen) {
                      setState(() => _imagenSeleccionada = imagen);
                    },
                  ),
                  const SizedBox(height: 16),
                  _InputCard(
                    child: TextFormField(
                      controller: _tituloCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Título de la novedad',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Ingresá el título';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InputCard(
                    child: TextFormField(
                      controller: _descripcionCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Ingresá la descripción';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InputCard(
                    child: TextFormField(
                      controller: _enlaceCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Enlace opcional',
                        hintText: 'https://...',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.open_in_new_rounded),
                      ),
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
                            decoration: const InputDecoration(
                              labelText: 'Orden',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.sort_rounded),
                            ),
                            validator: (value) {
                              final parsed = int.tryParse((value ?? '').trim());
                              if (parsed == null || parsed < 0) return 'Orden inválido';
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 74,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Visible',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)),
                                ),
                              ),
                              Switch(
                                value: _activo,
                                activeColor: const Color(0xFFE91E63),
                                onChanged: (value) => setState(() => _activo = value),
                              ),
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
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _savingLocal
                            ? 'Guardando...'
                            : editando
                                ? 'Actualizar novedad'
                                : 'Crear novedad',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
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
        );
      },
    );
  }
}

class _ProductoImagenSelector extends StatelessWidget {
  final TextEditingController productoNombreController;
  final bool buscando;
  final String? error;
  final List<ProductoNovedadBusquedaModel> productos;
  final ProductoImagenNovedadOption? imagenSeleccionada;
  final VoidCallback onBuscar;
  final VoidCallback onLimpiar;
  final ValueChanged<ProductoImagenNovedadOption> onSeleccionarImagen;

  const _ProductoImagenSelector({
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
        border: Border.all(color: const Color(0xFFE91E63).withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFFE91E63)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Buscar imagen por producto',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Escribí el nombre del producto y seleccioná una de sus imágenes disponibles.',
            style: TextStyle(color: Colors.grey.shade600, height: 1.35),
          ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: buscando ? null : onBuscar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: buscando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
            ),
          ],
          if (imagenSeleccionada != null && productos.isEmpty) ...[
            const SizedBox(height: 12),
            _SelectedExistingImageBadge(
              imagenId: imagenSeleccionada!.id,
              onClear: onLimpiar,
            ),
          ],
          if (productos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${productos.length} producto(s) encontrado(s)',
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onLimpiar,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...productos.map((producto) {
              final imagenes = producto.imagenes.take(2).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 245,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imagenes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final imagen = imagenes[index];
                          final selected = imagenSeleccionada?.id == imagen.id;

                          return _ProductoImagenOptionCard(
                            imagen: imagen,
                            selected: selected,
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

class _SelectedExistingImageBadge extends StatelessWidget {
  final int imagenId;
  final VoidCallback onClear;

  const _SelectedExistingImageBadge({required this.imagenId, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1).withAlpha(15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Color(0xFF5E35B1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Imagen vinculada actual: #$imagenId',
              style: const TextStyle(color: Color(0xFF5E35B1), fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: Color(0xFF5E35B1)),
          ),
        ],
      ),
    );
  }
}

class _ProductoImagenOptionCard extends StatelessWidget {
  final ProductoImagenNovedadOption imagen;
  final bool selected;
  final VoidCallback onTap;

  const _ProductoImagenOptionCard({
    required this.imagen,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: imagen.imagenUrl.isEmpty
          ? null
          : () => _openImagePreview(
                context,
                imageUrl: imagen.imagenUrl,
                title: 'Imagen #${imagen.id}',
              ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 215,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFE91E63) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? const Color(0xFFE91E63).withAlpha(40) : Colors.black.withAlpha(8),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: imagen.imagenUrl.isEmpty
                  ? const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                  : Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: Image.network(
                        imagen.imagenUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '#${imagen.id}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? const Color(0xFFE91E63) : Colors.white,
              ),
            ),
            if (imagen.esPrincipal)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Principal',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final File? foto;
  final String imageUrl;
  final VoidCallback onPick;

  const _ImagePickerBox({
    required this.foto,
    required this.imageUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = foto != null || imageUrl.trim().isNotEmpty;

    Widget content;

    if (foto != null) {
      content = Image.file(
        foto!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    } else if (imageUrl.isNotEmpty) {
      content = Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE91E63),
            ),
          );
        },
      );
    } else {
      content = const _ImagePlaceholder();
    }

    return InkWell(
      onTap: onPick,
      onLongPress: hasImage
          ? () => _openImagePreview(
                context,
                file: foto,
                imageUrl: imageUrl,
                title: 'Foto de novedad',
              )
          : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: content,
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _openImagePreview(
                          context,
                          file: foto,
                          imageUrl: imageUrl,
                          title: 'Foto de novedad',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(165),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_out_map_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Ver completa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: onPick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Cambiar foto',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFE91E63), size: 54),
          SizedBox(height: 8),
          Text(
            'Subir foto propia o elegir imagen de producto',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w800),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_outlined, color: Color(0xFFE91E63), size: 76),
          const SizedBox(height: 14),
          const Text(
            'No hay novedades todavía',
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea la primera novedad y selecciona imágenes de producto buscando por nombre.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear novedad'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String filtro;
  final VoidCallback onClear;

  const _NoSearchResults({required this.filtro, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, color: Color(0xFFE91E63), size: 72),
          const SizedBox(height: 14),
          const Text(
            'Sin resultados',
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'No encontré novedades con "$filtro".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Limpiar búsqueda'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 72),
          const SizedBox(height: 14),
          const Text(
            'No se pudieron cargar las novedades',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF2C3E50), fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
