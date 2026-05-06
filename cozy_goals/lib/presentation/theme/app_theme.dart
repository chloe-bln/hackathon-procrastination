import 'package:flutter/material.dart';

class CozyColors {
  static const cream = Color(0xFFFFF8EE);
  static const blush = Color(0xFFF8C8DC);
  static const lavender = Color(0xFFDCC7FF);
  static const mint = Color(0xFFCDECCF);
  static const sage = Color(0xFF8AAE92);
  static const cocoa = Color(0xFF6B4F4F);
  static const beige = Color(0xFFF4E1C1);
  static const roseText = Color(0xFF805B62);
  static const black = Color.fromARGB(255, 29, 20, 22);
  static const white = Color.fromARGB(255, 255, 255, 255);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: CozyColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CozyColors.blush,
        brightness: Brightness.light,
        primary: CozyColors.roseText,
        secondary: CozyColors.sage,
        surface: const Color(0xFFFFFCF7),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'sans',
        bodyColor: CozyColors.cocoa,
        displayColor: CozyColors.cocoa,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: CozyColors.cocoa,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFCF7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: CozyColors.sage, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: CozyColors.roseText,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CozyColors.roseText,
          side: const BorderSide(color: CozyColors.blush),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        ),
      ),
    );
  }
}
