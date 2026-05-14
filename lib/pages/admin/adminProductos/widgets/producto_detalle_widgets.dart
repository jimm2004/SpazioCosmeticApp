import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../models/producto_admin_model.dart';

class ProductoAndroidHeader extends StatelessWidget {
  final ProductoAdminModel producto;

  const ProductoAndroidHeader({
    super.key,
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    final total = producto.totalImagenes;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5E35B1),
            Color(0xFF7E57C2),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Fotos cargadas: $total / 2',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\$${producto.precioVenta.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductoPhotoSlots extends StatelessWidget {
  final ProductoAdminModel producto;
  final int slotSeleccionado;
  final File? imagenSeleccionada;
  final ValueChanged<int> onSelectSlot;

  const ProductoPhotoSlots({
    super.key,
    required this.producto,
    required this.slotSeleccionado,
    required this.imagenSeleccionada,
    required this.onSelectSlot,
  });

  @override
  Widget build(BuildContext context) {
    final foto1 = producto.imagenes.isNotEmpty ? producto.imagenes[0] : null;
    final foto2 = producto.imagenes.length > 1 ? producto.imagenes[1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotos del producto',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProductoPhotoSlotCard(
                title: 'Foto 1',
                subtitle: foto1 == null ? 'Ranura disponible' : 'Principal',
                selected: slotSeleccionado == 1,
                imagenSeleccionada:
                    slotSeleccionado == 1 ? imagenSeleccionada : null,
                imagenUrl: foto1?.imagenUrl,
                precioFinal: foto1?.precioFinal,
                isPrincipal: foto1?.esPrincipal ?? true,
                onTap: () => onSelectSlot(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProductoPhotoSlotCard(
                title: 'Foto 2',
                subtitle: foto2 == null ? 'Ranura disponible' : 'Secundaria',
                selected: slotSeleccionado == 2,
                imagenSeleccionada:
                    slotSeleccionado == 2 ? imagenSeleccionada : null,
                imagenUrl: foto2?.imagenUrl,
                precioFinal: foto2?.precioFinal,
                isPrincipal: foto2?.esPrincipal ?? false,
                onTap: () => onSelectSlot(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProductoPhotoSlotCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final File? imagenSeleccionada;
  final String? imagenUrl;
  final double? precioFinal;
  final bool isPrincipal;
  final VoidCallback onTap;

  const ProductoPhotoSlotCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.imagenSeleccionada,
    required this.imagenUrl,
    required this.precioFinal,
    required this.isPrincipal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tieneImagenUrl = imagenUrl != null && imagenUrl!.trim().isNotEmpty;
    final tieneNuevaImagen = imagenSeleccionada != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF5E35B1) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFF5E35B1).withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox.expand(
                      child: tieneNuevaImagen
                          ? Image.file(
                              imagenSeleccionada!,
                              fit: BoxFit.cover,
                            )
                          : tieneImagenUrl
                              ? Image.network(
                                  imagenUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return const ProductoSlotPlaceholder();
                                  },
                                )
                              : const ProductoSlotPlaceholder(),
                    ),
                  ),

                  if (tieneNuevaImagen)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _SlotChip(
                        text: 'Nueva',
                        color: Colors.orange.shade700,
                      ),
                    ),

                  if (isPrincipal)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _SlotChip(
                        text: 'Principal',
                        color: const Color(0xFF5E35B1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF5E35B1),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
            if (precioFinal != null && precioFinal! > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'Final \$${precioFinal!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String text;
  final Color color;

  const _SlotChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ProductoSlotPlaceholder extends StatelessWidget {
  const ProductoSlotPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.add_photo_alternate_rounded,
          size: 42,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

class PrecioFinalEditorCard extends StatelessWidget {
  final TextEditingController controller;
  final double precioVenta;
  final bool enabled;
  final bool ranuraOcupada;
  final bool tieneImagenNueva;

  const PrecioFinalEditorCard({
    super.key,
    required this.controller,
    required this.precioVenta,
    required this.enabled,
    required this.ranuraOcupada,
    required this.tieneImagenNueva,
  });

  @override
  Widget build(BuildContext context) {
    final helper = ranuraOcupada
        ? tieneImagenNueva
            ? 'Se guardará nuevo precio y nueva imagen.'
            : 'Puedes editar solo el precio final.'
        : 'Precio para la nueva imagen. Base: \$${precioVenta.toStringAsFixed(2)}';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_money_rounded,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Precio final',
                  helperText: helper,
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF5E35B1),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductoInfoSection extends StatelessWidget {
  final ProductoAdminModel producto;

  const ProductoInfoSection({
    super.key,
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    final precioFinal = producto.precioFinal > 0
        ? producto.precioFinal
        : producto.precioVenta;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.sell_rounded,
            label: 'Precio base',
            value: '\$${producto.precioVenta.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.local_offer_rounded,
            label: 'Precio final',
            value: '\$${precioFinal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.inventory_rounded,
            label: 'Stock',
            value: '${producto.cantidadStock}',
          ),
          const SizedBox(height: 16),
          const Text(
            'Descripción',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            producto.descripcion.isEmpty
                ? 'Este producto no tiene descripción.'
                : producto.descripcion,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF5E35B1), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ProductoVisibilityCard extends StatelessWidget {
  final bool esVisible;
  final ValueChanged<bool> onChanged;

  const ProductoVisibilityCard({
    super.key,
    required this.esVisible,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: esVisible
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    esVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: esVisible ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visible en catálogo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        esVisible
                            ? 'Los clientes pueden verlo'
                            : 'Oculto para clientes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: esVisible,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class ProductoImageActions extends StatelessWidget {
  final bool subiendo;
  final int totalImagenes;
  final int slotSeleccionado;
  final bool ranuraOcupada;
  final bool tieneImagenSeleccionada;
  final VoidCallback onTomarFoto;
  final VoidCallback onElegirGaleria;
  final VoidCallback onQuitarImagenSeleccionada;
  final VoidCallback onGuardarCambios;

  const ProductoImageActions({
    super.key,
    required this.subiendo,
    required this.totalImagenes,
    required this.slotSeleccionado,
    required this.ranuraOcupada,
    required this.tieneImagenSeleccionada,
    required this.onTomarFoto,
    required this.onElegirGaleria,
    required this.onQuitarImagenSeleccionada,
    required this.onGuardarCambios,
  });

  @override
  Widget build(BuildContext context) {
    final puedeCrearNueva = totalImagenes < 2;
    final puedeSeleccionarFoto = !subiendo && (ranuraOcupada || puedeCrearNueva);

    String descripcion;
    String botonTexto;
    IconData botonIcono;

    if (ranuraOcupada && tieneImagenSeleccionada) {
      descripcion =
          'Ranura $slotSeleccionado ocupada. Se reemplazará la imagen anterior y se guardará el precio final.';
      botonTexto = 'Cambiar imagen y guardar precio';
      botonIcono = Icons.swap_horiz_rounded;
    } else if (ranuraOcupada && !tieneImagenSeleccionada) {
      descripcion =
          'Ranura $slotSeleccionado ocupada. Puedes actualizar solo el precio final.';
      botonTexto = 'Actualizar precio final';
      botonIcono = Icons.price_change_rounded;
    } else {
      descripcion =
          'Ranura $slotSeleccionado disponible. Selecciona una imagen para cargarla.';
      botonTexto = 'Guardar imagen ${totalImagenes + 1}/2';
      botonIcono = Icons.cloud_upload_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de fotografía',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: puedeSeleccionarFoto ? onTomarFoto : null,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Cámara'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF5E35B1),
                    side: const BorderSide(color: Color(0xFF5E35B1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: puedeSeleccionarFoto ? onElegirGaleria : null,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Galería'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF5E35B1),
                    side: const BorderSide(color: Color(0xFF5E35B1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (tieneImagenSeleccionada) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: subiendo ? null : onQuitarImagenSeleccionada,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Quitar selección'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: subiendo ? null : onGuardarCambios,
              icon: subiendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(botonIcono),
              label: Text(
                subiendo ? 'Guardando cambios...' : botonTexto,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ranuraOcupada
                    ? const Color(0xFF2C3E50)
                    : const Color(0xFF5E35B1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}