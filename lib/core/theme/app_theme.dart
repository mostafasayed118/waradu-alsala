import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF0D3B0D);
  static const Color ivory = Color(0xFFFFFBF0);
  static const Color gold = Color(0xFFD4AF37);
  static const Color lightGold = Color(0xFFF5E6B8);

  // Light Theme
  static ThemeData lightTheme() {
    return _build(
      brightness: Brightness.light,
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: gold,
      surface: ivory,
      appBarBackground: primaryGreen,
      bodyColor: Colors.black87,
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    return _build(
      brightness: Brightness.dark,
      seedColor: lightGreen,
      primary: lightGreen,
      secondary: lightGold,
      surface: darkGreen,
      appBarBackground: darkGreen,
      bodyColor: Colors.white70,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color seedColor,
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color appBarBackground,
    required Color bodyColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: bodyColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: bodyColor,
        ),
      ),
    );
  }
}

