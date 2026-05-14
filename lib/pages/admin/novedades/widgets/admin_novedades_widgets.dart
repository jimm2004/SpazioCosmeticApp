import 'package:flutter/material.dart';

import '../../../../controllers/admin/admin_novedades_controller.dart';
import '../../../../models/novedad_model.dart';
import 'novedades_web_safe_network_image.dart';

const kNovedadPink = Color(0xFFE91E63);
const kNovedadPurple = Color(0xFF5E35B1);
const kNovedadText = Color(0xFF2C3E50);
const kNovedadBg = Color(0xFFF4F6FB);

class AdminNovedadesStatsHeader extends StatelessWidget {
  final int total;
  final int visibles;
  final int ocultas;
  final int conImagen;
  final int sinImagen;
  final int filtradas;
  final bool isWide;
  final VoidCallback onRefresh;

  const AdminNovedadesStatsHeader({
    super.key,
    required this.total,
    required this.visibles,
    required this.ocultas,
    required this.conImagen,
    required this.sinImagen,
    required this.filtradas,
    required this.isWide,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 12, isWide ? 24 : 16, 8),
          child: Container(
            padding: EdgeInsets.all(isWide ? 22 : 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kNovedadPink, kNovedadPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: kNovedadPink.withOpacity(0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: isWide ? _desktop() : _mobile(),
          ),
        ),
      ),
    );
  }

  Widget _desktop() {
    return Row(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel dinámico de novedades',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                'Gestiona banners, fotos y orden sin quemar la API. KPI visual, servidor respirando.',
                style: TextStyle(color: Colors.white.withOpacity(0.84), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: _chips()),
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
            foregroundColor: kNovedadPink,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }

  Widget _mobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Novedades dinámicas',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filled(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kNovedadPink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Control rápido de publicaciones para catálogo.',
          style: TextStyle(color: Colors.white.withOpacity(0.84), fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _chips().map((w) => Padding(padding: const EdgeInsets.only(right: 10), child: w)).toList()),
        ),
      ],
    );
  }

  List<Widget> _chips() => [
        _StatChip(icon: Icons.inventory_2_rounded, label: 'Total', value: '$total'),
        _StatChip(icon: Icons.filter_alt_rounded, label: 'Vista', value: '$filtradas'),
        _StatChip(icon: Icons.visibility_rounded, label: 'Visibles', value: '$visibles'),
        _StatChip(icon: Icons.visibility_off_rounded, label: 'Ocultas', value: '$ocultas'),
        _StatChip(icon: Icons.image_rounded, label: 'Con imagen', value: '$conImagen'),
        _StatChip(icon: Icons.image_not_supported_rounded, label: 'Sin imagen', value: '$sinImagen'),
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

class AdminNovedadSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isWide;

  const AdminNovedadSearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1180 : 920),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 8, isWide ? 24 : 16, 8),
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
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por título, descripción u orden...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: kNovedadPink),
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

class AdminNovedadFilterRail extends StatelessWidget {
  final AdminNovedadFiltro filtro;
  final ValueChanged<AdminNovedadFiltro> onChanged;
  final int Function(AdminNovedadFiltro filtro) countFor;
  final bool isWide;

  const AdminNovedadFilterRail({
    super.key,
    required this.filtro,
    required this.onChanged,
    required this.countFor,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final filtros = AdminNovedadFiltro.values;
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
                avatar: Icon(_iconFor(item), size: 18, color: selected ? Colors.white : kNovedadPink),
                label: Text('${adminNovedadFiltroLabel(item)} · ${countFor(item)}'),
                labelStyle: TextStyle(color: selected ? Colors.white : kNovedadText, fontWeight: FontWeight.w800),
                selectedColor: kNovedadPink,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? kNovedadPink : Colors.grey.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (_) => onChanged(item),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AdminNovedadFiltro f) {
    switch (f) {
      case AdminNovedadFiltro.todas:
        return Icons.campaign_rounded;
      case AdminNovedadFiltro.visibles:
        return Icons.visibility_rounded;
      case AdminNovedadFiltro.ocultas:
        return Icons.visibility_off_rounded;
      case AdminNovedadFiltro.conImagen:
        return Icons.image_rounded;
      case AdminNovedadFiltro.sinImagen:
        return Icons.image_not_supported_rounded;
    }
  }
}

class AdminNovedadesActionBar extends StatelessWidget {
  final bool isGridView;
  final int totalFiltradas;
  final AdminNovedadFiltro filtro;
  final VoidCallback onToggleView;
  final VoidCallback onRefresh;
  final bool isWide;

  const AdminNovedadesActionBar({
    super.key,
    required this.isGridView,
    required this.totalFiltradas,
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
                  '$totalFiltradas novedades · ${adminNovedadFiltroLabel(filtro)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kNovedadText, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton.filledTonal(onPressed: onRefresh, tooltip: 'Actualizar novedades', icon: const Icon(Icons.sync_rounded)),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onToggleView,
                tooltip: isGridView ? 'Ver como lista' : 'Ver como cuadrícula',
                style: IconButton.styleFrom(backgroundColor: kNovedadPink, foregroundColor: Colors.white),
                icon: Icon(isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NovedadesEmptySliver extends StatelessWidget {
  const NovedadesEmptySliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 76, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text('No hay novedades para mostrar', style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Cambia el filtro o crea una nueva publicación.', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class NovedadesGridSliver extends StatelessWidget {
  final List<NovedadModel> novedades;
  final int crossAxisCount;
  final EdgeInsets padding;
  final void Function(NovedadModel novedad) onEdit;
  final void Function(NovedadModel novedad) onDelete;
  final void Function(NovedadModel novedad, bool value) onToggle;

  const NovedadesGridSliver({
    super.key,
    required this.novedades,
    required this.crossAxisCount,
    required this.padding,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: crossAxisCount >= 3 ? 0.74 : 0.70,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final novedad = novedades[index];
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 160 + (index * 25).clamp(0, 260).toInt()),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
              ),
              child: NovedadCard(
                novedad: novedad,
                onEdit: () => onEdit(novedad),
                onDelete: () => onDelete(novedad),
                onToggle: (value) => onToggle(novedad, value),
              ),
            );
          },
          childCount: novedades.length,
        ),
      ),
    );
  }
}

class NovedadesListSliver extends StatelessWidget {
  final List<NovedadModel> novedades;
  final EdgeInsets padding;
  final void Function(NovedadModel novedad) onEdit;
  final void Function(NovedadModel novedad) onDelete;
  final void Function(NovedadModel novedad, bool value) onToggle;

  const NovedadesListSliver({
    super.key,
    required this.novedades,
    required this.padding,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final novedad = novedades[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NovedadListTile(
                novedad: novedad,
                onEdit: () => onEdit(novedad),
                onDelete: () => onDelete(novedad),
                onToggle: (value) => onToggle(novedad, value),
              ),
            );
          },
          childCount: novedades.length,
        ),
      ),
    );
  }
}

class NovedadCard extends StatelessWidget {
  final NovedadModel novedad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const NovedadCard({
    super.key,
    required this.novedad,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _cleanImage(novedad.imagenPrincipal);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: novedad.activo ? kNovedadPink.withOpacity(0.25) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                NovedadesWebSafeNetworkImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: const Icon(Icons.image_outlined, size: 56, color: Colors.grey),
                ),
                Positioned(left: 10, top: 10, child: _StatusBadge(activo: novedad.activo)),
                Positioned(right: 10, top: 10, child: _OrderBadge(orden: novedad.orden)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        novedad.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kNovedadText, fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Switch(value: novedad.activo, activeColor: kNovedadPink, onChanged: onToggle),
                  ],
                ),
                Text(
                  novedad.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Editar'))),
                    const SizedBox(width: 8),
                    IconButton.outlined(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
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

class NovedadListTile extends StatelessWidget {
  final NovedadModel novedad;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const NovedadListTile({
    super.key,
    required this.novedad,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _cleanImage(novedad.imagenPrincipal);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 128,
                  height: 96,
                  child: NovedadesWebSafeNetworkImage(
                    url: imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(18),
                    errorWidget: const Icon(Icons.image_outlined, size: 42, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [_StatusBadge(activo: novedad.activo), const SizedBox(width: 8), _OrderBadge(orden: novedad.orden)]),
                      const SizedBox(height: 8),
                      Text(novedad.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kNovedadText, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 5),
                      Text(novedad.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, height: 1.32)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(value: novedad.activo, activeColor: kNovedadPink, onChanged: onToggle),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: kNovedadPurple)),
                        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(activo ? 'Visible' : 'Oculta', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
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
      decoration: BoxDecoration(color: kNovedadPink.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
      child: Text('Orden $orden', style: const TextStyle(color: kNovedadPink, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

String _cleanImage(String value) {
  final clean = value.trim();
  if (clean.isEmpty || clean.toLowerCase() == 'null') return '';
  return clean;
}
