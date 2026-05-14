import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Acoplamiento simple para Windows / iOS / Android sin romper compilación web.
///
/// Úsalo para centralizar baseUrl, layout responsive y detalles de plataforma.
class MoodPlatformConfig {
  static const String productionApiBaseUrl =
      'https://lavenderblush-crocodile-665497.hostingersite.com/api';

  /// Cambia esto en desarrollo si vas a probar Laravel local.
  /// Windows: http://127.0.0.1:8000/api
  /// iOS simulator: http://127.0.0.1:8000/api si Laravel corre en tu Mac.
  /// Dispositivo físico: usa ngrok/hostinger/tu dominio HTTPS.
  static const String localApiBaseUrl = 'http://127.0.0.1:8000/api';

  static TargetPlatform get platform => defaultTargetPlatform;

  static bool get isIOS => platform == TargetPlatform.iOS;
  static bool get isWindows => platform == TargetPlatform.windows;
  static bool get isAndroid => platform == TargetPlatform.android;
  static bool get isDesktop =>
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.macOS ||
      platform == TargetPlatform.linux;

  /// En producción usa siempre HTTPS. iOS es más delicado con HTTP por ATS.
  static String apiBaseUrl({bool useLocal = false}) {
    if (useLocal) return localApiBaseUrl;
    return productionApiBaseUrl;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1100) return const EdgeInsets.all(28);
    if (width >= 700) return const EdgeInsets.all(22);
    return const EdgeInsets.all(14);
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1100) return 1050;
    if (width >= 700) return 760;
    return width;
  }
}
