// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WebSafeNetworkImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  /// Si es true, el <img> HTML no se crea hasta que el widget entra al viewport.
  /// Esto reduce cientos de GET al abrir catálogo, pedidos o grids largos.
  final bool loadOnlyWhenVisible;

  /// Si el usuario va haciendo scroll rápido, retrasa la imagen unos milisegundos.
  final bool deferWhileScrolling;

  /// Tamaño sugerido para navegadores que respetan width/height en el elemento.
  /// No recorta la imagen; solo ayuda al layout del HTML.
  final int? cacheWidth;
  final int? cacheHeight;

  const WebSafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.loadingWidget,
    this.backgroundColor,
    this.borderRadius,
    this.loadOnlyWhenVisible = true,
    this.deferWhileScrolling = true,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<WebSafeNetworkImage> createState() => _WebSafeNetworkImageState();
}

class _WebSafeNetworkImageState extends State<WebSafeNetworkImage>
    with AutomaticKeepAliveClientMixin {
  static final Set<String> _registeredViewTypes = <String>{};

  late final Key _visibilityKey = UniqueKey();
  late String _viewType;

  bool _shouldLoad = false;
  bool _scheduledAfterScroll = false;

  @override
  bool get wantKeepAlive => _shouldLoad;

  @override
  void initState() {
    super.initState();
    _shouldLoad = !widget.loadOnlyWhenVisible;
    _buildViewType();
    if (_shouldLoad) _registerView();
  }

  @override
  void didUpdateWidget(covariant WebSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed = oldWidget.url != widget.url ||
        oldWidget.fit != widget.fit ||
        oldWidget.cacheWidth != widget.cacheWidth ||
        oldWidget.cacheHeight != widget.cacheHeight;

    if (!changed) return;

    _shouldLoad = !widget.loadOnlyWhenVisible;
    _scheduledAfterScroll = false;
    _buildViewType();

    if (_shouldLoad) _registerView();
    updateKeepAlive();
  }

  void _buildViewType() {
    final cleanUrl = _cleanUrl(widget.url);
    final hash = Object.hash(
      cleanUrl,
      widget.fit.name,
      widget.cacheWidth ?? 0,
      widget.cacheHeight ?? 0,
    );

    _viewType = 'mood-safe-img-$hash';
  }

  void _markVisible(VisibilityInfo info) {
    if (_shouldLoad || !mounted) return;
    if (info.visibleFraction <= 0.01) return;

    _registerView();

    setState(() {
      _shouldLoad = true;
    });

    updateKeepAlive();
  }

  void _scheduleAfterFastScroll() {
    if (_scheduledAfterScroll || _shouldLoad || !mounted) return;

    _scheduledAfterScroll = true;

    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _shouldLoad) return;

      _registerView();

      setState(() {
        _shouldLoad = true;
        _scheduledAfterScroll = false;
      });

      updateKeepAlive();
    });
  }

  void _registerView() {
    final cleanUrl = _cleanUrl(widget.url);

    if (cleanUrl.isEmpty) return;
    if (_registeredViewTypes.contains(_viewType)) return;

    _registeredViewTypes.add(_viewType);

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
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.setProperty('object-fit', _objectFit(widget.fit))
        ..style.setProperty('object-position', 'center center')
        ..style.display = 'block'
        ..style.border = '0'
        ..style.userSelect = 'none';

      img
        ..setAttribute('loading', 'lazy')
        ..setAttribute('decoding', 'async')
        ..setAttribute('fetchpriority', 'low')
        ..setAttribute('draggable', 'false')
        ..setAttribute('referrerpolicy', 'no-referrer');

      if (widget.cacheWidth != null && widget.cacheWidth! > 0) {
        img.width = widget.cacheWidth!;
      }

      if (widget.cacheHeight != null && widget.cacheHeight! > 0) {
        img.height = widget.cacheHeight!;
      }

      wrapper.children.add(img);
      return wrapper;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final cleanUrl = _cleanUrl(widget.url);
    final fallback = widget.errorWidget ??
        const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        );

    Widget body;

    if (cleanUrl.isEmpty) {
      body = Center(child: fallback);
    } else if (!_shouldLoad) {
      body = widget.loadingWidget ??
          _ImageSkeleton(backgroundColor: widget.backgroundColor);
    } else {
      final shouldDefer =
          widget.deferWhileScrolling && Scrollable.recommendDeferredLoadingForContext(context);

      if (shouldDefer) {
        _scheduleAfterFastScroll();
        body = widget.loadingWidget ??
            _ImageSkeleton(backgroundColor: widget.backgroundColor);
      } else {
        _registerView();
        body = HtmlElementView(viewType: _viewType);
      }
    }

    Widget boxed = Container(
      width: widget.width,
      height: widget.height,
      color: widget.backgroundColor,
      child: body,
    );

    if (widget.borderRadius != null) {
      boxed = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: boxed,
      );
    }

    if (!widget.loadOnlyWhenVisible || _shouldLoad || cleanUrl.isEmpty) {
      return boxed;
    }

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _markVisible,
      child: boxed,
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  final Color? backgroundColor;

  const _ImageSkeleton({this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? const Color(0xFFF7F3F6),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.black26,
          size: 34,
        ),
      ),
    );
  }
}

String _cleanUrl(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return '';
  return text;
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
