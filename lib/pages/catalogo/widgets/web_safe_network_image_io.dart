import 'package:flutter/material.dart';

class WebSafeNetworkImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: errorWidget ?? const Icon(Icons.image_not_supported_outlined),
      );
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => errorWidget ?? const Icon(Icons.image_not_supported_outlined),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return loadingWidget ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      ),
    );
  }
}
