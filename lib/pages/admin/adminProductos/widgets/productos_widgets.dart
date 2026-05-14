import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/producto_admin_model.dart';
import 'web_safe_network_image.dart';

const _adminPurple = Color(0xFF5E35B1);
const _adminPurpleLight = Color(0xFF7E57C2);
const _adminText = Color(0xFF2C3E50);
const _adminBg = Color(0xFFF5F7FA);

enum AdminProductoFiltro {
  todos,
  visibles,
  ocultos,
  conFotos,
  sinFotos,
  sinStock,
}

String adminProductoFiltroLabel(AdminProductoFiltro filtro) {
  switch (filtro) {
    case AdminProductoFiltro.todos:
      return 'Todos';
    case AdminProductoFiltro.visibles:
      return 'Visibles';
    case AdminProductoFiltro.ocultos:
      return 'Ocultos';
    case AdminProductoFiltro.conFotos:
      return 'Con fotos';
    case AdminProductoFiltro.sinFotos:
      return 'Sin fotos';
    case AdminProductoFiltro.sinStock:
      return 'Sin stock';
  }
}

IconData adminProductoFiltroIcon(AdminProductoFiltro filtro) {
  switch (filtro) {
    case AdminProductoFiltro.todos:
      return Icons.inventory_2_rounded;
    case AdminProductoFiltro.visibles:
      return Icons.visibility_rounded;
    case AdminProductoFiltro.ocultos:
      return Icons.visibility_off_rounded;
    case AdminProductoFiltro.conFotos:
      return Icons.photo_library_rounded;
    case AdminProductoFiltro.sinFotos:
      return Icons.image_not_supported_rounded;
    case AdminProductoFiltro.sinStock:
      return Icons.warning_amber_rounded;
  }
}

class AdminProductosStatsHeader extends StatelessWidget {
  final int total;
  final int visibles;
  final int conFotos;
  final int sinFotos;
  final int filtrados;
  final int sinStock;
  final bool isWide;
  final VoidCallback onRefresh;

  const AdminProductosStatsHeader({
    super.key,
    required this.total,
    required this.visibles,
    required this.conFotos,
    required this.sinFotos,
    required this.filtrados,
    required this.sinStock,
    required this.isWide,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 10, isWide ? 24 : 16, 6),
          child: Container(
            padding: EdgeInsets.all(isWide ? 22 : 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_adminPurple, _adminPurpleLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _adminPurple.withOpacity(0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: isWide ? _desktop(context) : _mobile(context),
          ),
        ),
      ),
    );
  }

  Widget _desktop(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel visual de productos',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                'Fotos, visibilidad, stock y precio final con lectura rápida. KPI listo, estrés fuera del backlog.',
                style: TextStyle(color: Colors.white.withOpacity(0.82), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _chips(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Actualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: _adminPurple,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Panel visual de productos',
                style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filled(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _adminPurple),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Control rápido de catálogo y fotos.',
          style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _chips().map((e) => Padding(padding: const EdgeInsets.only(right: 10), child: e)).toList()),
        ),
      ],
    );
  }

  List<Widget> _chips() => [
        _StatChip(icon: Icons.inventory_2_rounded, label: 'Total', value: '$total'),
        _StatChip(icon: Icons.filter_alt_rounded, label: 'Vista', value: '$filtrados'),
        _StatChip(icon: Icons.visibility_rounded, label: 'Visibles', value: '$visibles'),
        _StatChip(icon: Icons.photo_library_rounded, label: 'Con fotos', value: '$conFotos'),
        _StatChip(icon: Icons.image_not_supported_rounded, label: 'Sin fotos', value: '$sinFotos'),
        _StatChip(icon: Icons.inventory_rounded, label: 'Sin stock', value: '$sinStock'),
      ];
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class AdminProductoSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String>? onSubmitted;
  final bool isWide;

  const AdminProductoSearchBox({
    super.key,
    required this.controller,
    required this.onClear,
    this.onSubmitted,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 10, isWide ? 24 : 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.055), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Buscar producto, descripción, stock o precio...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: _adminPurple),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.grey), onPressed: onClear)
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminProductoFilterRail extends StatelessWidget {
  final AdminProductoFiltro filtro;
  final ValueChanged<AdminProductoFiltro> onChanged;
  final int Function(AdminProductoFiltro filtro) countFor;
  final bool isWide;

  const AdminProductoFilterRail({
    super.key,
    required this.filtro,
    required this.onChanged,
    required this.countFor,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final filtros = AdminProductoFiltro.values;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: SizedBox(
          height: 48,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
            scrollDirection: Axis.horizontal,
            itemCount: filtros.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = filtros[index];
              final selected = item == filtro;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(
                  adminProductoFiltroIcon(item),
                  size: 18,
                  color: selected ? Colors.white : _adminPurple,
                ),
                label: Text('${adminProductoFiltroLabel(item)} · ${countFor(item)}'),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _adminText,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: _adminPurple,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? _adminPurple : Colors.grey.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (_) => onChanged(item),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdminProductosActionBar extends StatelessWidget {
  final bool isGridView;
  final int totalFiltrados;
  final AdminProductoFiltro filtro;
  final VoidCallback onToggleView;
  final VoidCallback onRefresh;
  final bool isWide;

  const AdminProductosActionBar({
    super.key,
    required this.isGridView,
    required this.totalFiltrados,
    required this.filtro,
    required this.onToggleView,
    required this.onRefresh,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 8, isWide ? 24 : 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$totalFiltrados productos · ${adminProductoFiltroLabel(filtro)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _adminText, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onRefresh,
                tooltip: 'Actualizar catálogo',
                icon: const Icon(Icons.sync_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onToggleView,
                tooltip: isGridView ? 'Ver como lista' : 'Ver como cuadrícula',
                style: IconButton.styleFrom(backgroundColor: _adminPurple, foregroundColor: Colors.white),
                icon: Icon(isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductoEmptyState extends StatelessWidget {
  const ProductoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.48,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No se encontraron productos', style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Cambia el filtro o busca otra palabra.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class ProductoEmptyStateSliver extends StatelessWidget {
  const ProductoEmptyStateSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No se encontraron productos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Cambia el filtro o busca otra palabra. El tablero no encontró match en esta ronda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductoListSliver extends StatelessWidget {
  final List<ProductoAdminModel> productos;
  final Future<void> Function(int idProducto) onTapProducto;
  final EdgeInsets padding;

  const ProductoListSliver({
    super.key,
    required this.productos,
    required this.onTapProducto,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final producto = productos[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 150 + (index * 18).clamp(0, 220).toInt()),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
              ),
              child: ProductoListCard(
                producto: producto,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  onTapProducto(producto.idProducto);
                },
              ),
            );
          },
          childCount: productos.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}

class ProductoGridSliver extends StatelessWidget {
  final List<ProductoAdminModel> productos;
  final int crossAxisCount;
  final Future<void> Function(int idProducto) onTapProducto;
  final EdgeInsets padding;
  final bool isWide;

  const ProductoGridSliver({
    super.key,
    required this.productos,
    required this.crossAxisCount,
    required this.onTapProducto,
    required this.padding,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: isWide ? 18 : 14,
          mainAxisSpacing: isWide ? 18 : 14,
          childAspectRatio: isWide ? 0.72 : 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final producto = productos[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 150 + (index * 18).clamp(0, 220).toInt()),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
              ),
              child: ProductoGridCard(
                producto: producto,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  onTapProducto(producto.idProducto);
                },
              ),
            );
          },
          childCount: productos.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}

class ProductoListView extends StatelessWidget {
  final List<ProductoAdminModel> productos;
  final Future<void> Function(int idProducto) onTapProducto;
  final bool isWide;

  const ProductoListView({
    super.key,
    required this.productos,
    required this.onTapProducto,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: ListView.builder(
          cacheExtent: 0,
          addAutomaticKeepAlives: false,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 8, isWide ? 24 : 16, 28),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 180 + (index * 28).clamp(0, 260).toInt()),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
              ),
              child: ProductoListCard(
                producto: producto,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  onTapProducto(producto.idProducto);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductoGridView extends StatelessWidget {
  final List<ProductoAdminModel> productos;
  final int crossAxisCount;
  final Future<void> Function(int idProducto) onTapProducto;
  final bool isWide;

  const ProductoGridView({
    super.key,
    required this.productos,
    required this.crossAxisCount,
    required this.onTapProducto,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1280 : 980),
        child: GridView.builder(
          cacheExtent: 0,
          addAutomaticKeepAlives: false,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 8, isWide ? 24 : 16, 28),
          itemCount: productos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isWide ? 18 : 14,
            mainAxisSpacing: isWide ? 18 : 14,
            childAspectRatio: isWide ? 0.72 : 0.68,
          ),
          itemBuilder: (context, index) {
            final producto = productos[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 180 + (index * 28).clamp(0, 260).toInt()),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
              ),
              child: ProductoGridCard(
                producto: producto,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  onTapProducto(producto.idProducto);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductoListCard extends StatefulWidget {
  final ProductoAdminModel producto;
  final VoidCallback onTap;

  const ProductoListCard({super.key, required this.producto, required this.onTap});

  @override
  State<ProductoListCard> createState() => _ProductoListCardState();
}

class _ProductoListCardState extends State<ProductoListCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final producto = widget.producto;
    final totalFotos = producto.totalImagenes;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.006 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _hover ? _adminPurple.withOpacity(0.25) : Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(_hover ? 0.08 : 0.04), blurRadius: _hover ? 18 : 12, offset: const Offset(0, 5))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ProductoImagesPreview(
                      producto: producto,
                      height: 104,
                      width: 132,
                      borderRadius: BorderRadius.circular(18),
                      mode: ProductoImagesPreviewMode.list,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: ProductoCardInfo(producto: producto, isGrid: false)),
                    Column(
                      children: [
                        _MiniStatusChip(
                          text: '$totalFotos/2 fotos',
                          color: totalFotos >= 2 ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(height: 10),
                        _MiniStatusChip(
                          text: (producto.activo ?? true) ? 'Visible' : 'Oculto',
                          color: (producto.activo ?? true) ? Colors.green : Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductoGridCard extends StatefulWidget {
  final ProductoAdminModel producto;
  final VoidCallback onTap;

  const ProductoGridCard({super.key, required this.producto, required this.onTap});

  @override
  State<ProductoGridCard> createState() => _ProductoGridCardState();
}

class _ProductoGridCardState extends State<ProductoGridCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final imageRadius = const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.012 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _hover ? _adminPurple.withOpacity(0.25) : Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(_hover ? 0.09 : 0.05), blurRadius: _hover ? 20 : 12, offset: const Offset(0, 5))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProductoImagesPreview(
                      producto: widget.producto,
                      height: double.infinity,
                      width: double.infinity,
                      borderRadius: imageRadius,
                      mode: ProductoImagesPreviewMode.grid,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ProductoCardInfo(producto: widget.producto, isGrid: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniStatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

enum ProductoImagesPreviewMode { list, grid }

class ProductoImagesPreview extends StatefulWidget {
  final ProductoAdminModel producto;
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final ProductoImagesPreviewMode mode;

  const ProductoImagesPreview({
    super.key,
    required this.producto,
    required this.height,
    required this.width,
    required this.borderRadius,
    required this.mode,
  });

  @override
  State<ProductoImagesPreview> createState() => _ProductoImagesPreviewState();
}

class _ProductoImagesPreviewState extends State<ProductoImagesPreview> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotos = _fotoItems(widget.producto);
    final grid = widget.mode == ProductoImagesPreviewMode.grid;

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (fotos.isEmpty)
              ProductoImagePlaceholder(iconSize: grid ? 48 : 34)
            else
              PageView.builder(
                controller: _controller,
                itemCount: fotos.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, i) => ProductoImageTile(
                  imagenUrl: fotos[i].url,
                  label: '${i + 1}',
                  isPrincipal: fotos[i].principal,
                  borderRadius: BorderRadius.zero,
                  iconSize: grid ? 42 : 32,
                ),
              ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.58), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  fotos.isEmpty ? '0/2 fotos' : '${_index + 1}/${fotos.length} fotos',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (fotos.length > 1)
              Positioned(
                right: 8,
                bottom: 9,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(fotos.length, (i) {
                    final selected = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(left: 4),
                      width: selected ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(0.52),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_FotoItem> _fotoItems(ProductoAdminModel producto) {
    final result = <_FotoItem>[];
    for (final foto in producto.imagenes) {
      final url = (foto.imagenUrl ?? '').trim();
      if (url.isEmpty || url.toLowerCase() == 'null') continue;
      result.add(_FotoItem(url: url, principal: foto.esPrincipal));
    }
    final fallback = (producto.imagenUrl ?? '').trim();
    if (result.isEmpty && fallback.isNotEmpty && fallback.toLowerCase() != 'null') {
      result.add(_FotoItem(url: fallback, principal: true));
    }
    return result;
  }
  
}

class _FotoItem {
  final String url;
  final bool principal;
  const _FotoItem({required this.url, required this.principal});
}


class LazyViewportNetworkImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final double preloadExtent;

  const LazyViewportNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.loadingWidget,
    this.preloadExtent = 220,
  });

  @override
  State<LazyViewportNetworkImage> createState() => _LazyViewportNetworkImageState();
}

class _LazyViewportNetworkImageState extends State<LazyViewportNetworkImage> {
  final GlobalKey _imageKey = GlobalKey();
  ScrollPosition? _scrollPosition;
  Timer? _timer;
  bool _shouldLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (_scrollPosition != nextPosition) {
      _scrollPosition?.removeListener(_scheduleCheck);
      _scrollPosition?.isScrollingNotifier.removeListener(_scheduleCheck);
      _scrollPosition = nextPosition;
      _scrollPosition?.addListener(_scheduleCheck);
      _scrollPosition?.isScrollingNotifier.addListener(_scheduleCheck);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(covariant LazyViewportNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _shouldLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollPosition?.removeListener(_scheduleCheck);
    _scrollPosition?.isScrollingNotifier.removeListener(_scheduleCheck);
    super.dispose();
  }

  void _scheduleCheck() {
    if (_shouldLoad || !mounted) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 90), _checkVisibility);
  }

  void _checkVisibility() {
    if (!mounted || _shouldLoad) return;

    final cleanUrl = (widget.url ?? '').trim();
    if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') return;

    final imageContext = _imageKey.currentContext;
    final renderObject = imageContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
      return;
    }

    final media = MediaQuery.maybeOf(context);
    if (media == null) {
      setState(() => _shouldLoad = true);
      return;
    }

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    final preload = widget.preloadExtent;
    final screenSize = media.size;

    final isNearViewport =
        topLeft.dy < screenSize.height + preload &&
        topLeft.dy + size.height > -preload &&
        topLeft.dx < screenSize.width + preload &&
        topLeft.dx + size.width > -preload;

    if (!isNearViewport) return;

    if (Scrollable.recommendDeferredLoadingForContext(context)) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 180), _checkVisibility);
      return;
    }

    setState(() => _shouldLoad = true);
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = (widget.url ?? '').trim();
    final fallback = widget.errorWidget ?? const Icon(Icons.image_not_supported_outlined, color: Colors.grey);

    Widget child;
    if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') {
      child = Center(child: fallback);
    } else if (_shouldLoad) {
      child = WebSafeNetworkImage(
        url: cleanUrl,
        fit: widget.fit,
        borderRadius: widget.borderRadius,
        loadingWidget: widget.loadingWidget,
        errorWidget: fallback,
      );
    } else {
      child = widget.loadingWidget ??
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: widget.borderRadius),
            child: Center(
              child: Icon(Icons.image_search_rounded, color: Colors.grey.shade400, size: 34),
            ),
          );
    }

    return KeyedSubtree(key: _imageKey, child: child);
  }
}

class ProductoImageTile extends StatelessWidget {
  final String? imagenUrl;
  final String label;
  final bool isPrincipal;
  final BorderRadius borderRadius;
  final double iconSize;

  const ProductoImageTile({
    super.key,
    required this.imagenUrl,
    required this.label,
    required this.isPrincipal,
    required this.borderRadius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final url = imagenUrl?.trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: borderRadius),
          child: LazyViewportNetworkImage(
            url: url,
            fit: BoxFit.cover,
            borderRadius: borderRadius,
            preloadExtent: 180,
            errorWidget: ProductoImagePlaceholder(iconSize: iconSize),
          ),
        ),
        Positioned(
          top: 7,
          left: 7,
          child: _PhotoChip(text: 'Foto $label', color: Colors.black.withOpacity(0.64)),
        ),
        if (isPrincipal)
          Positioned(
            top: 7,
            right: 7,
            child: _PhotoChip(text: 'Principal', color: _adminPurple.withOpacity(0.92)),
          ),
      ],
    );
  }
}

class _PhotoChip extends StatelessWidget {
  final String text;
  final Color color;
  const _PhotoChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

class ProductoImagePlaceholder extends StatelessWidget {
  final double iconSize;
  const ProductoImagePlaceholder({super.key, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(child: Icon(Icons.add_photo_alternate_rounded, size: iconSize, color: Colors.grey.shade400)),
    );
  }
}

class ProductoCardInfo extends StatelessWidget {
  final ProductoAdminModel producto;
  final bool isGrid;

  const ProductoCardInfo({super.key, required this.producto, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    final esVisible = producto.activo ?? true;
    final precioFinal = producto.precioFinal > 0 ? producto.precioFinal : producto.precioVenta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          producto.nombre,
          style: TextStyle(fontSize: isGrid ? 14 : 16, fontWeight: FontWeight.w900, color: _adminText, height: 1.15),
          maxLines: isGrid ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Flexible(
              child: Text(
                '\$${precioFinal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: isGrid ? 17 : 16, fontWeight: FontWeight.w900, color: Colors.green.shade700),
              ),
            ),
            const SizedBox(width: 8),
            if (precioFinal != producto.precioVenta)
              Flexible(
                child: Text(
                  'Base \$${producto.precioVenta.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: isGrid ? 11 : 12, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Stock: ${producto.cantidadStock}',
          style: TextStyle(
            fontSize: isGrid ? 12 : 13,
            color: producto.cantidadStock > 0 ? Colors.grey.shade700 : Colors.redAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ProductoVisibilityBadge(esVisible: esVisible),
            ProductoPhotoBadge(totalFotos: producto.totalImagenes),
            if (producto.cantidadStock <= 0) const ProductoStockBadge(),
          ],
        ),
      ],
    );
  }
}

class ProductoVisibilityBadge extends StatelessWidget {
  final bool esVisible;
  const ProductoVisibilityBadge({super.key, required this.esVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (esVisible ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        esVisible ? 'Visible' : 'Oculto',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: esVisible ? Colors.green.shade700 : Colors.red.shade700),
      ),
    );
  }
}

class ProductoPhotoBadge extends StatelessWidget {
  final int totalFotos;
  const ProductoPhotoBadge({super.key, required this.totalFotos});

  @override
  Widget build(BuildContext context) {
    final completo = totalFotos >= 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (completo ? _adminPurple : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        completo ? '2 fotos' : '$totalFotos/2 fotos',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: completo ? _adminPurple : Colors.orange.shade700),
      ),
    );
  }
}

class ProductoStockBadge extends StatelessWidget {
  const ProductoStockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: const Text('Sin stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.redAccent)),
    );
  }
}
