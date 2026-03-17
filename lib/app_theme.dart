import 'package:flutter/material.dart';

/// App theme constants and styles.
/// Primary color: #0052CC (elderly-friendly, high contrast)
class AppTheme {
  AppTheme._();

  /// Primary brand color - Blue #0052CC
  static const Color primaryColor = Color(0xFF0052CC);

  /// Safe status color (green)
  static const Color safeColor = Color(0xFF22C55E);

  /// Danger status color (red)
  static const Color dangerColor = Color(0xFFE00000);

  /// Warning status color (amber/yellow)
  static const Color warningColor = Color(0xFFF59E0B);

  /// Minimum body font size (18px)
  static const double bodyFontSize = 18;

  /// Minimum title font size (24px)
  static const double titleFontSize = 24;

  /// Main app theme
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: bodyFontSize),
          bodyMedium: TextStyle(fontSize: bodyFontSize),
          bodySmall: TextStyle(fontSize: 16),
        ),
      );
}
