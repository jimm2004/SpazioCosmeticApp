import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ Necesario para saber si estamos en Web (kIsWeb)
import 'package:flutter/gestures.dart';   // ✅ Necesario para permitir el scroll con mouse
import 'pages/auth/auth_page.dart';

// ✅ CLASE DE CONFIGURACIÓN DINÁMICA
class AppConfig {
  static const String _puertoFijo = "55474"; // El puerto que no cambia nunca

  // Ahora baseUrl es "dinámico" (un getter)
  static String get baseUrl {
    if (kIsWeb) {
      // Si la app está corriendo en Web, toma la IP que aparece en el navegador
      final String hostActual = Uri.base.host;
      return "http://$hostActual:$_puertoFijo";
    } else {
      // Si llegas a correr la app nativa en un Emulador de Android
      // 10.0.2.2 es el alias que usa Android para "localhost"
      return "http://10.0.2.2:$_puertoFijo"; 
    }
  }
}

void main() {
  runApp(const SpazioCosmeticApp());
}

class SpazioCosmeticApp extends StatelessWidget {
  const SpazioCosmeticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spazio Cosmetic | Nicaragua',
      debugShowCheckedModeBanner: false,

      // ✅ ESTO PERMITE QUE PUEDAS DAR CLIC Y ARRASTRAR PARA BAJAR/SUBIR (SCROLL)
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      ),

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          primary: Colors.black,
          secondary: const Color(0xFFE91E63),
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),

        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFFE91E63),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.black,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),

      home: const AuthHomePage(),
    );
  }
}