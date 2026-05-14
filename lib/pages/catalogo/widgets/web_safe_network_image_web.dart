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

  /// Si es true, NO crea el <img> hasta que el widget entra al viewport.
  /// Esto evita cientos de peticiones de imágenes al abrir catálogo/pedidos.
  final bool loadOnlyWhenVisible;

  final bool deferWhileScrolling;

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
  });

  @override
  State<WebSafeNetworkImage> createState() => _WebSafeNetworkImageState();
}

class _WebSafeNetworkImageState extends State<WebSafeNetworkImage> {
  static final Set<String> _registeredViewTypes = <String>{};

  late final Key _visibilityKey = UniqueKey();
  late String _viewType;
  bool _shouldLoad = false;
  bool _scheduledAfterScroll = false;

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
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _shouldLoad = !widget.loadOnlyWhenVisible;
      _scheduledAfterScroll = false;
      _buildViewType();
      if (_shouldLoad) _registerView();
    }
  }

  void _buildViewType() {
    final cleanUrl = (widget.url ?? '').trim();
    _viewType = 'mood-safe-img-${cleanUrl.hashCode}-${widget.fit.name}-${widget.width ?? 0}-${widget.height ?? 0}';
  }

  void _markVisible(VisibilityInfo info) {
    if (_shouldLoad || !mounted) return;
    if (info.visibleFraction <= 0.01) return;
    _registerView();
    setState(() => _shouldLoad = true);
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
    });
  }

  void _registerView() {
    final cleanUrl = (widget.url ?? '').trim();
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

      if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') {
        wrapper.text = '';
        return wrapper;
      }

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

      wrapper.children.add(img);
      return wrapper;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanUrl = (widget.url ?? '').trim();
    final fallback = widget.errorWidget ?? const Icon(Icons.image_not_supported_outlined, color: Colors.grey);

    Widget body;
    if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') {
      body = Center(child: fallback);
    } else if (!_shouldLoad) {
      body = widget.loadingWidget ?? _ImageSkeleton(backgroundColor: widget.backgroundColor);
    } else {
      final shouldDefer = widget.deferWhileScrolling && Scrollable.recommendDeferredLoadingForContext(context);
      if (shouldDefer) {
        _scheduleAfterFastScroll();
        body = widget.loadingWidget ?? _ImageSkeleton(backgroundColor: widget.backgroundColor);
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
      boxed = ClipRRect(borderRadius: widget.borderRadius!, child: boxed);
    }

    if (!widget.loadOnlyWhenVisible || _shouldLoad || cleanUrl.isEmpty) return boxed;

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
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.black26, size: 34)),
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
    case BoxFit.fitWidth:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
