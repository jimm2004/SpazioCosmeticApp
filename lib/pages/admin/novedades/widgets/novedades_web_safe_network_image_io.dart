import 'package:flutter/material.dart';

class NovedadesWebSafeNetworkImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cleanUrl = (url ?? '').trim();
    final fallback = errorWidget ?? const Icon(Icons.image_not_supported_outlined, color: Colors.grey);

    Widget child;
    if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') {
      child = Center(child: fallback);
    } else {
      child = Image.network(
        cleanUrl,
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (_, image, frame, __) {
          if (frame != null) return image;
          return loadingWidget ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => Center(child: fallback),
      );
    }

    final boxed = Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: child,
    );

    if (borderRadius == null) return boxed;
    return ClipRRect(borderRadius: borderRadius!, child: boxed);
  }
}
