import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class WebSafeNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Color? backgroundColor;

  const WebSafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
    this.backgroundColor,
  });

  @override
  State<WebSafeNetworkImage> createState() => _WebSafeNetworkImageState();
}

class _WebSafeNetworkImageState extends State<WebSafeNetworkImage> {
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _registerView(widget.url);
  }

  @override
  void didUpdateWidget(covariant WebSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _registerView(widget.url);
    }
  }

  void _registerView(String rawUrl) {
    final cleanUrl = rawUrl.trim();
    _viewType = 'web-safe-image-${DateTime.now().microsecondsSinceEpoch}-${cleanUrl.hashCode}-${widget.fit.name}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final wrapper = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.backgroundColor = 'transparent';

      final img = html.ImageElement()
        ..src = cleanUrl
        ..draggable = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _objectFit(widget.fit)
        ..style.objectPosition = 'center center'
        ..style.display = 'block'
        ..style.border = '0'
        ..style.userSelect = 'none';

      // Usamos <img> real para Flutter Web. Esto evita que CanvasKit/WebGL
      // intente leer bytes por XHR/fetch y choque con CORS en imágenes públicas.
      wrapper.children.add(img);
      return wrapper;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = widget.url.trim();

    if (cleanUrl.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget ?? const Icon(Icons.image_not_supported_outlined),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor,
      child: HtmlElementView(viewType: _viewType),
    );
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
      return 'contain';
    case BoxFit.fitWidth:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
