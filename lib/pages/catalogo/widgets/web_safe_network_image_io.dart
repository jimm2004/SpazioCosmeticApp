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

  /// Si es true, no crea Image.network hasta que el widget entra al viewport.
  /// Esto evita que Android/iOS/desktop descarguen imágenes que todavía no se ven.
  final bool loadOnlyWhenVisible;

  /// Evita que se pidan imágenes mientras el usuario hace scroll rápido.
  final bool deferWhileScrolling;

  /// Reduce uso de memoria cuando Flutter decodifica imágenes grandes.
  /// No cambia el archivo del servidor; solo la decodificación local.
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
  late final Key _visibilityKey = UniqueKey();

  bool _shouldLoad = false;
  bool _scheduledAfterScroll = false;

  @override
  bool get wantKeepAlive => _shouldLoad;

  @override
  void initState() {
    super.initState();
    _shouldLoad = !widget.loadOnlyWhenVisible;
  }

  @override
  void didUpdateWidget(covariant WebSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed = oldWidget.url != widget.url ||
        oldWidget.cacheWidth != widget.cacheWidth ||
        oldWidget.cacheHeight != widget.cacheHeight;

    if (!changed) return;

    _shouldLoad = !widget.loadOnlyWhenVisible;
    _scheduledAfterScroll = false;
    updateKeepAlive();
  }

  void _markVisible(VisibilityInfo info) {
    if (_shouldLoad || !mounted) return;
    if (info.visibleFraction <= 0.01) return;

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

      setState(() {
        _shouldLoad = true;
        _scheduledAfterScroll = false;
      });

      updateKeepAlive();
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
        body = Image.network(
          cleanUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          filterQuality: FilterQuality.low,
          gaplessPlayback: false,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return widget.loadingWidget ??
                _ImageSkeleton(backgroundColor: widget.backgroundColor);
          },
          errorBuilder: (_, __, ___) => Center(child: fallback),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return widget.loadingWidget ??
                const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
          },
        );
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
