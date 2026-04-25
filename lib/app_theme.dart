import 'package:flutter/material.dart';

/// App-wide design tokens & Material 3 themes.
/// Light:  Icy-white bg · Navy primary · Mint Green accent
/// Dark:   Space-Black bg · #1E1E1E surface · Neon Mint accent
class AppTheme {
  AppTheme._();

  // ── Brand colours ───────────────────────────────────────────────────────────

  /// Legacy alias kept so existing const refs compile without change.
  static const Color primaryColor = navyColor;

  static const Color navyColor      = Color(0xFF1A2440);
  static const Color mintColor      = Color(0xFF00C896); // Light mode accent
  static const Color neonMint       = Color(0xFF00E5B0); // Dark mode accent
  static const Color icyWhite       = Color(0xFFF0F4FF); // Legacy light bg tint
  static const Color spaceBlack     = Color(0xFF0B132B); // Legacy dark bg
  static const Color darkBg         = Color(0xFF121212); // Dark scaffold bg
  static const Color darkSurface    = Color(0xFF1E1E1E); // Dark surface
  static const Color navyCard       = Color(0xFF1A2440); // Dark AI result cards

  // ── Status colours (unchanged) ──────────────────────────────────────────────

  static const Color safeColor    = Color(0xFF22C55E);
  static const Color dangerColor  = Color(0xFFE00000);
  static const Color warningColor = Color(0xFFF59E0B);

  // ── Two-Tone Typography colours ─────────────────────────────────────────────

  /// Dark navy/black used for the first (foreground) word in ModernHeader.
  static const Color textForeground = Color(0xFF111827);

  /// Teal/green accent used for the second (accent) word in ModernHeader.
  static const Color textAccent = Color(0xFF00C48C);

  /// Glowing shadow color applied behind the accent word in ModernHeader.
  static const Color accentShadow = Color.fromRGBO(0, 255, 178, 0.5);

  // ── Font sizes (unchanged) ──────────────────────────────────────────────────

  static const double bodyFontSize  = 18;
  static const double titleFontSize = 24;

  // ── Light Theme ─────────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: navyColor,
          primary: navyColor,
          secondary: mintColor,
          surface: Colors.white,
          error: dangerColor,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: navyColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: mintColor.withOpacity(0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: navyColor);
            }
            return const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: navyColor, size: 26);
            }
            return const IconThemeData(color: Colors.grey, size: 24);
          }),
          elevation: 8,
          shadowColor: navyColor.withOpacity(0.08),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: navyColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navyColor,
            side: const BorderSide(color: navyColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? mintColor : Colors.grey),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? mintColor.withOpacity(0.35)
                  : Colors.grey.withOpacity(0.2)),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: navyColor),
          displayMedium:
              TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: navyColor),
          displaySmall: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: navyColor),
          headlineLarge:
              TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navyColor),
          headlineMedium:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyColor),
          headlineSmall:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor),
          titleLarge:
              TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: navyColor),
          titleMedium: TextStyle(
              fontSize: bodyFontSize,
              fontWeight: FontWeight.w600,
              color: navyColor),
          titleSmall:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: navyColor),
          bodyLarge:
              TextStyle(fontSize: bodyFontSize, color: Color(0xFF2A3550)),
          bodyMedium:
              TextStyle(fontSize: bodyFontSize, color: Color(0xFF2A3550)),
          bodySmall: TextStyle(fontSize: 16, color: Color(0xFF5A6375)),
        ),
        dividerColor: Colors.grey.shade200,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  // ── Dark Theme ──────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: neonMint,
          primary: neonMint,
          secondary: neonMint,
          surface: darkSurface,
          error: dangerColor,
          brightness: Brightness.dark,
        ).copyWith(
          surface: darkSurface,
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: darkBg,
        cardColor: navyCard,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1B35),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0D1B35),
          indicatorColor: neonMint.withOpacity(0.20),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: neonMint);
            }
            return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.5));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: neonMint, size: 26);
            }
            return IconThemeData(
                color: Colors.white.withOpacity(0.5), size: 24);
          }),
          elevation: 8,
          shadowColor: Colors.black54,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonMint,
            foregroundColor: spaceBlack,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: neonMint,
            side: const BorderSide(color: neonMint),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? neonMint : Colors.grey),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? neonMint.withOpacity(0.35)
                  : Colors.white.withOpacity(0.1)),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium:
              TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          displaySmall: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white),
          headlineLarge:
              TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          headlineSmall:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge:
              TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          titleMedium: TextStyle(
              fontSize: bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white),
          titleSmall: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: TextStyle(fontSize: bodyFontSize, color: Color(0xFFCDD5E0)),
          bodyMedium:
              TextStyle(fontSize: bodyFontSize, color: Color(0xFFCDD5E0)),
          bodySmall: TextStyle(fontSize: 16, color: Color(0xFF8B94A8)),
        ),
        dividerColor: Colors.white.withOpacity(0.08),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  /// Legacy alias: returns lightTheme so existing code that references
  /// `AppTheme.theme` still compiles.
  static ThemeData get theme => lightTheme;
}
