import 'package:flutter/material.dart';

/// Design tokens and high-contrast theme tailored for market stalls and outdoor conditions.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF1A1F2C);
  static const Color surfaceElevated = Color(0xFF242B3D);
  static const Color border = Color(0xFF333E54);

  // Lightning & Bitcoin accents
  static const Color lightningGold = Color(0xFFF7931A);
  static const Color lightningAmber = Color(0xFFFFB020);

  // Action Tile Color Themes (High contrast, instantly recognizable)
  static const Color receiveGreen = Color(0xFF10B981);
  static const Color receiveGreenSurface = Color(0xFF064E3B);

  static const Color sendIndigo = Color(0xFF6366F1);
  static const Color sendIndigoSurface = Color(0xFF312E81);

  static const Color activityBlue = Color(0xFF3B82F6);
  static const Color activityBlueSurface = Color(0xFF1E3A8A);

  static const Color voiceAmber = Color(0xFFF59E0B);
  static const Color voiceAmberSurface = Color(0xFF78350F);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

class AppTheme {
  static const double minTouchTarget = 52.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.lightningGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.lightningGold,
        secondary: AppColors.receiveGreen,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          backgroundColor: AppColors.lightningGold,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
