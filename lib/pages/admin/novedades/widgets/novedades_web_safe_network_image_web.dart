// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class NovedadesWebSafeNetworkImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const NovedadesWebSafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<NovedadesWebSafeNetworkImage> createState() =>
      _NovedadesWebSafeNetworkImageState();
}

class _NovedadesWebSafeNetworkImageState
    extends State<NovedadesWebSafeNetworkImage> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant NovedadesWebSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _registerView();
    }
  }

  void _registerView() {
    final cleanUrl = (widget.url ?? '').trim();
    _viewType =
        'novedad-safe-image-${DateTime.now().microsecondsSinceEpoch}-${cleanUrl.hashCode}-${widget.fit.name}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final wrapper = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.backgroundColor = 'transparent';

      if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') {
        wrapper.text = '';
        return wrapper;
      }

      final img = html.ImageElement()
        ..src = cleanUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.border = '0'
        ..style.userSelect = 'none';

      // Compatibilidad Flutter Web/Dart: algunas versiones de dart:html
      // no exponen `loading`, `decoding` o `draggable` como setters.
      // setAttribute evita esos errores y mantiene lazy loading real en web.
      img
        ..setAttribute('loading', 'lazy')
        ..setAttribute('decoding', 'async')
        ..setAttribute('fetchpriority', 'low')
        ..setAttribute('draggable', 'false');

      img.style
        ..setProperty('object-fit', _objectFit(widget.fit))
        ..setProperty('object-position', 'center center');

      wrapper.children.add(img);
      return wrapper;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = (widget.url ?? '').trim();
    final fallback = widget.errorWidget ??
        const Icon(Icons.image_not_supported_outlined, color: Colors.grey);

    final child = cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null'
        ? Center(child: fallback)
        : HtmlElementView(viewType: _viewType);

    final boxed = Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor,
      child: child,
    );

    if (widget.borderRadius == null) return boxed;
    return ClipRRect(borderRadius: widget.borderRadius!, child: boxed);
  }
}

String _objectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitHeight:
    case BoxFit.fitWidth:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
