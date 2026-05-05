import 'package:flutter/material.dart';

class MoodPalette {
  static const dark = Color(0xFF15172B);
  static const black = Color(0xFF050509);
  static const pink = Color(0xFFE91E63);
  static const hotPink = Color(0xFFEC4899);
  static const purple = Color(0xFF5E35B1);
  static const deepPurple = Color(0xFF7E22CE);
  static const softPink = Color(0xFFFFEEF7);
  static const softPurple = Color(0xFFF3E8FF);
  static const background = Color(0xFFFFFBFE);
  static const text = Color(0xFF1F1F1F);
  static const muted = Color(0xFF6B7280);

  static const mainGradient = LinearGradient(
    colors: [dark, purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow cardShadow([double alpha = 0.08]) => BoxShadow(
        color: Colors.black.withOpacity(alpha),
        blurRadius: 18,
        offset: const Offset(0, 8),
      );
}
