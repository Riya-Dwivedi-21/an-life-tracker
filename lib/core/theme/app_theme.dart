import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF8BBDDD);
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF98FB98);
  static const Color accentPink = Color(0xFFFFB6C1);
  static const Color accentBlue = Color(0xFFADD8E6);
  static const Color accentGreen = Color(0xFF98FB98);
  static const Color success = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF1A1A2E);
  static const Color muted = Color(0xFFF0F0F5);
  static const Color border = Color(0xFFE0E0E0);
}

class AppTheme {
  // Habit Tracker Colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryPurple = Color(0xFF9B59B6);
  static const Color backgroundColor = Color(0xFF0F0F1E);
  static const Color cardColor = Color(0xFF1A1A2E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.foreground),
        titleTextStyle: TextStyle(
          color: AppColors.foreground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
