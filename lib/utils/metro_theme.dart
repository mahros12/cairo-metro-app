import 'package:cairo_metro_app/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MetroTheme {
  // Line 1: Blue (Cairo Metro Line 1)
  static const Color line1Color = Color(0xFF1E88E5);
  static const Color line1Light = Color(0xFFE3F2FD);

  // Line 2: Red (Cairo Metro Line 2)
  static const Color line2Color = Color(0xFFD32F2F);
  static const Color line2Light = Color(0xFFFFEBEE);

  // Line 3: Green (Cairo Metro Line 3)
  static const Color line3Color = Color(0xFF2E7D32);
  static const Color line3Light = Color(0xFFE8F5E9);

  // Light Mode Colors
  static const Color primaryDark = Color(0xFF1E293B);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color dividerColorLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color dividerColorDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  /// Checks if the app is currently in dark mode
  static bool get isDark {
    if (Get.isRegistered<ThemeController>()) {
      return Get.find<ThemeController>().isDarkMode.value;
    }
    return Get.isDarkMode;
  }

  // Adaptive theme colors
  static Color get background => isDark ? backgroundDark : backgroundLight;
  static Color get surface => isDark ? surfaceDark : surfaceLight;
  static Color get cardColor => isDark ? surfaceDark : surfaceLight;
  static Color get cardSecondary => isDark ? const Color(0xFF253346) : const Color(0xFFF1F5F9);
  static Color get inputFill => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color get dividerColor => isDark ? dividerColorDark : dividerColorLight;
  static Color get textPrimary => isDark ? textPrimaryDark : textPrimaryLight;
  static Color get textSecondary => isDark ? textSecondaryDark : textSecondaryLight;
  static Color get textMuted => isDark ? textMutedDark : textMutedLight;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    cardColor: surfaceLight,
    canvasColor: surfaceLight,
    dividerColor: dividerColorLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLight,
      modalBackgroundColor: surfaceLight,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: line1Color,
      primary: line1Color,
      brightness: Brightness.light,
      surface: surfaceLight,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    cardColor: surfaceDark,
    canvasColor: surfaceDark,
    dividerColor: dividerColorDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceDark,
      modalBackgroundColor: surfaceDark,
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: dividerColorDark),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceDark,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: line1Color,
      primary: line1Color,
      brightness: Brightness.dark,
      surface: surfaceDark,
    ),
  );

  static Color getLineColor(int line) {
    switch (line) {
      case 1:
        return line1Color;
      case 2:
        return line2Color;
      case 3:
        return line3Color;
      default:
        return const Color(0xFF64748B);
    }
  }

  static Color getLineLightColor(int line) {
    if (isDark) {
      return getLineColor(line).withValues(alpha: 0.2);
    }
    switch (line) {
      case 1:
        return line1Light;
      case 2:
        return line2Light;
      case 3:
        return line3Light;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static String getLineName(int line) {
    switch (line) {
      case 1:
        return "Line 1";
      case 2:
        return "Line 2";
      case 3:
        return "Line 3";
      default:
        return "Line $line";
    }
  }

  static String getLineFullName(int line) {
    switch (line) {
      case 1:
        return "Line 1 (Helwan ↔ New El Marg)";
      case 2:
        return "Line 2 (El Mounib ↔ Shubra)";
      case 3:
        return "Line 3 (Green Line)";
      default:
        return "Line $line";
    }
  }

  /// Calculates official Cairo Metro ticket price based on station count.
  /// 1 - 9 stations: 10 EGP
  /// 10 - 16 stations: 12 EGP
  /// 17 - 23 stations: 15 EGP
  /// > 23 stations: 20 EGP
  static int calculateFare(int stationCount) {
    if (stationCount <= 0) return 0;
    if (stationCount <= 9) return 10;
    if (stationCount <= 16) return 12;
    if (stationCount <= 23) return 15;
    return 20;
  }

  /// Calculates half-price fare for passengers over 60 years old.
  /// 1 - 9 stations: 5 EGP
  /// 10 - 16 stations: 6 EGP
  /// 17 - 23 stations: 8 EGP
  /// > 23 stations: 10 EGP
  static int calculateOver60Fare(int stationCount) {
    if (stationCount <= 0) return 0;
    if (stationCount <= 9) return 5;
    if (stationCount <= 16) return 6;
    if (stationCount <= 23) return 8;
    return 10;
  }

  /// Estimates travel time in minutes (approx. 2.5 min per station + 5 min per transfer)
  static String calculateEstimatedTime(int stationCount, int transfersCount) {
    if (stationCount <= 1) return "0 min";
    final totalMinutes = ((stationCount - 1) * 2.5).round() + (transfersCount * 5);
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? "$hours hr $minutes min" : "$hours hr";
    }
    return "$totalMinutes min";
  }
}
