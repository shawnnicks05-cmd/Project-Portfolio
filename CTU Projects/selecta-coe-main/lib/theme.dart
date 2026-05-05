// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFC8102E);
  static const Color primaryLight = Color(0xFFE5263A);
  static const Color accent = Color(0xFF000000);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFB91C1C);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1F2937);
  static const Color border = Color(0xFF374151);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          secondary: accent,
          surface: surface,
        ),
        scaffoldBackgroundColor: surfaceVariant,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      );

  static Color levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return success;
      case 'advanced':
        return primary;
      case 'intermediate':
        return warning;
      default:
        return textMuted;
    }
  }

  static Color barColor(double percent) {
    if (percent >= 85) return success;
    if (percent >= 65) return primary;
    if (percent >= 45) return warning;
    return danger;
  }
}
