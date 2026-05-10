// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors
  static const Color darkPrimary = Color(0xFFC8102E);
  static const Color darkPrimaryLight = Color(0xFFE5263A);
  static const Color darkAccent = Color(0xFF000000);
  static const Color darkSuccess = Color(0xFF10B981);
  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkDanger = Color(0xFFB91C1C);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceVariant = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white;
  static const Color darkTextMuted = Colors.white;
  static const Color darkBackground = Color(0xFF111827);

  // Light theme colors
  static const Color lightPrimary = Color(0xFFC8102E);
  static const Color lightPrimaryLight = Color(0xFFE5263A);
  static const Color lightAccent = Color(0xFF000000);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightDanger = Color(0xFFB91C1C);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Colors.black; // Changed to black for light mode
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF6B7280);
  static const Color lightBackground = Color(0xFFF9FAFB);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: lightPrimary,
          secondary: lightAccent,
          surface: lightSurface,
        ),
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: lightSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: lightTextPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: lightBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightPrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(color: lightTextMuted, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimary,
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

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: darkPrimary,
          secondary: darkAccent,
          surface: darkSurface,
          surfaceContainerLowest: darkSurface,
          surfaceContainerLow: darkSurface,
          surfaceContainer: darkSurface,
          surfaceContainerHigh: darkSurfaceVariant,
          surfaceContainerHighest: darkSurfaceVariant,
          outline: darkBorder,
        ),
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: darkTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: darkTextPrimary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: darkBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkPrimary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkPrimary,
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

  // Keep backward compatibility - now responsive to theme mode
  static Color getColor(BuildContext context, Color lightColor, Color darkColor) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  static Color getPrimary(BuildContext context) => getColor(context, lightPrimary, darkPrimary);
  static Color getPrimaryLight(BuildContext context) => getColor(context, lightPrimaryLight, darkPrimaryLight);
  static Color getAccent(BuildContext context) => getColor(context, lightAccent, darkAccent);
  static Color getSuccess(BuildContext context) => getColor(context, lightSuccess, darkSuccess);
  static Color getWarning(BuildContext context) => getColor(context, lightWarning, darkWarning);
  static Color getDanger(BuildContext context) => getColor(context, lightDanger, darkDanger);
  static Color getSurface(BuildContext context) => getColor(context, lightSurface, darkSurface);
  static Color getSurfaceVariant(BuildContext context) => getColor(context, lightSurfaceVariant, darkSurfaceVariant);
  static Color getBorder(BuildContext context) => getColor(context, lightBorder, darkBorder);
  static Color getTextPrimary(BuildContext context) => getColor(context, lightTextPrimary, darkTextPrimary);
  static Color getTextSecondary(BuildContext context) => getColor(context, lightTextSecondary, darkTextSecondary);
  static Color getTextMuted(BuildContext context) => getColor(context, lightTextMuted, darkTextMuted);
  static Color getBackground(BuildContext context) => getColor(context, lightBackground, darkBackground);

  // Legacy getters for backward compatibility (default to dark theme)
  static Color get primary => darkPrimary;
  static Color get primaryLight => darkPrimaryLight;
  static Color get accent => darkAccent;
  static Color get success => darkSuccess;
  static Color get warning => darkWarning;
  static Color get danger => darkDanger;
  static Color get surface => darkSurface;
  static Color get surfaceVariant => darkSurfaceVariant;
  static Color get border => darkBorder;
  static Color get textPrimary => darkTextPrimary;
  static Color get textSecondary => darkTextSecondary;
  static Color get textMuted => darkTextMuted;
  static Color get background => darkBackground;

  static Color levelColor(String level, {bool isDark = true}) {
    final colors = isDark ? darkThemeColors : lightThemeColors;
    switch (level.toLowerCase()) {
      case 'expert':
        return colors['success']!;
      case 'advanced':
        return colors['primary']!;
      case 'intermediate':
        return colors['warning']!;
      default:
        return colors['textMuted']!;
    }
  }

  static Color barColor(double percent, {bool isDark = true}) {
    final colors = isDark ? darkThemeColors : lightThemeColors;
    if (percent >= 85) return colors['success']!;
    if (percent >= 65) return colors['primary']!;
    if (percent >= 45) return colors['warning']!;
    return colors['danger']!;
  }

  static Map<String, Color> get darkThemeColors => {
    'primary': darkPrimary,
    'success': darkSuccess,
    'warning': darkWarning,
    'danger': darkDanger,
    'textMuted': darkTextMuted,
  };

  static Map<String, Color> get lightThemeColors => {
    'primary': lightPrimary,
    'success': lightSuccess,
    'warning': lightWarning,
    'danger': lightDanger,
    'textMuted': lightTextMuted,
  };
}
