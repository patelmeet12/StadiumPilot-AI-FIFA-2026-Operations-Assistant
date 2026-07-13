import 'package:flutter/material.dart';

class AppTheme {
  // FIFA Inspired Colors
  static const Color primaryGreen = Color(0xFF00875A); // Rich Emerald Green
  static const Color accentGold = Color(0xFFFFC72C); // Vibrant Gold
  static const Color darkPitch = Color(0xFF0B1410); // Deep Pitch Navy/Green
  static const Color pitchCard = Color(
    0xFF14241E,
  ); // Dark green card background
  static const Color lightField = Color(0xFFF4F7F5); // Soft light background
  static const Color alertPurple = Color(0xFF6366F1); // Operations Royal Purple
  static const Color errorRed = Color(0xFFEF4444);

  // High Contrast Colors
  static const Color hcBg = Color(0xFF000000);
  static const Color hcSurface = Color(0xFF121212);
  static const Color hcText = Color(0xFFFFFFFF);
  static const Color hcYellow = Color(0xFFFFE600);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGold,
        tertiary: alertPurple,
        surface: Colors.white,
        error: errorRed,
      ),
      scaffoldBackgroundColor: lightField,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: darkPitch,
          fontFamily: 'Outfit',
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: darkPitch,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: darkPitch,
          fontFamily: 'Outfit',
        ),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: darkPitch),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGold,
        tertiary: alertPurple,
        surface: pitchCard,
        error: errorRed,
      ),
      scaffoldBackgroundColor: darkPitch,
      cardTheme: CardThemeData(
        color: pitchCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Outfit',
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Outfit',
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPitch,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // High Contrast Theme (Accessibility First)
  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: hcYellow,
        secondary: hcText,
        tertiary: hcYellow,
        surface: hcSurface,
        error: Colors.red,
      ),
      scaffoldBackgroundColor: hcBg,
      cardTheme: CardThemeData(
        color: hcSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: hcText, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          color: hcText,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w900,
          color: hcText,
          fontSize: 26,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: hcYellow,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: hcText,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: hcText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: hcText, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: hcBg,
        foregroundColor: hcText,
        elevation: 2,
        iconTheme: IconThemeData(color: hcText, size: 30),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hcYellow,
          foregroundColor: hcBg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: hcText, width: 2),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      iconTheme: const IconThemeData(color: hcYellow, size: 28),
    );
  }
}
