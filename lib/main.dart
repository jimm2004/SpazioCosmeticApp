import 'package:flutter/material.dart';
import 'pages/auth/auth_page.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          primary: Colors.black,
          secondary: const Color(0xFFE91E63),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthHomePage(),
    );
  }
}