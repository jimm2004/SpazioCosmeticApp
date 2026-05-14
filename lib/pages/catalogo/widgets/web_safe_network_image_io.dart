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

  /// Si es true, NO crea Image.network hasta que el widget entra al viewport.
  /// Funciona en Android, iOS, Windows, macOS, Linux y Web.
  final bool loadOnlyWhenVisible;

  /// Evita que se pidan imágenes mientras el usuario hace scroll rápido.
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
  late final Key _visibilityKey = UniqueKey();
  bool _shouldLoad = false;
  bool _scheduledAfterScroll = false;

  @override
  void didUpdateWidget(covariant WebSafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _shouldLoad = !widget.loadOnlyWhenVisible;
      _scheduledAfterScroll = false;
    }
  }

  void _markVisible(VisibilityInfo info) {
    if (_shouldLoad || !mounted) return;
    if (info.visibleFraction <= 0.01) return;
    setState(() => _shouldLoad = true);
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
      body = widget.loadingWidget ?? _ImageSkeleton(icon: Icons.image_outlined, backgroundColor: widget.backgroundColor);
    } else {
      final shouldDefer = widget.deferWhileScrolling && Scrollable.recommendDeferredLoadingForContext(context);
      if (shouldDefer) {
        _scheduleAfterFastScroll();
        body = widget.loadingWidget ?? _ImageSkeleton(icon: Icons.image_outlined, backgroundColor: widget.backgroundColor);
      } else {
        body = Image.network(
          cleanUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          filterQuality: FilterQuality.low,
          gaplessPlayback: false,
          errorBuilder: (_, __, ___) => Center(child: fallback),
          loadingBuilder: (_, imageChild, progress) {
            if (progress == null) return imageChild;
            return widget.loadingWidget ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
  final IconData icon;
  final Color? backgroundColor;

  const _ImageSkeleton({required this.icon, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? const Color(0xFFF7F3F6),
      child: Center(
        child: Icon(icon, color: Colors.black26, size: 34),
      ),
    );
  }
}
