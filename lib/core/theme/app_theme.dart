import 'package:flutter/material.dart';

/// Clean Light Theme tokens (White Default)
/// High-contrast, extreme outdoor legibility, minimal cognitive load.
class AppColors {
  // Backgrounds - Clean, crisp white & soft slate
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Lightning Accent - Warm Bitcoin Amber
  static const Color lightningGold = Color(0xFFF59E0B);
  static const Color lightningAmber = Color(0xFFD97706);

  // Typography Scale Colors - Rich dark slate
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Financial Indicators
  static const Color success = Color(0xFF10B981); // Inbound / Confirmed
  static const Color error = Color(0xFFEF4444);   // Outbound / Failure
  static const Color warning = Color(0xFFF59E0B);

  // Backward compatibility aliases
  static const Color receiveGreen = Color(0xFF10B981);
  static const Color receiveGreenSurface = Color(0xFFECFDF5);
  static const Color sendIndigo = Color(0xFF0F172A);
  static const Color sendIndigoSurface = Color(0xFFF8FAFC);
  static const Color activityBlue = Color(0xFF0F172A);
  static const Color activityBlueSurface = Color(0xFFF8FAFC);
  static const Color voiceAmber = Color(0xFFF59E0B);
  static const Color voiceAmberSurface = Color(0xFFFFFBEB);
}

/// Dark Theme tokens
class AppColorsDark {
  static const Color background = Color(0xFF0C0D10);
  static const Color surface = Color(0xFF14161C);
  static const Color surfaceElevated = Color(0xFF1C1F27);
  static const Color border = Color(0xFF262A36);
  static const Color borderSubtle = Color(0xFF1D212A);

  static const Color lightningGold = Color(0xFFF59E0B);
  static const Color lightningAmber = Color(0xFFD97706);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color receiveGreen = Color(0xFF10B981);
  static const Color receiveGreenSurface = Color(0xFF14161C);
  static const Color sendIndigo = Color(0xFFF8FAFC);
  static const Color sendIndigoSurface = Color(0xFF1C1F27);
  static const Color activityBlue = Color(0xFFF8FAFC);
  static const Color activityBlueSurface = Color(0xFF1C1F27);
  static const Color voiceAmber = Color(0xFFF59E0B);
  static const Color voiceAmberSurface = Color(0xFF1C1F27);
}

class AppTheme {
  static const double minTouchTarget = 52.0;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.lightningGold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightningGold,
        secondary: AppColors.textPrimary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.0),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsDark.background,
      primaryColor: AppColorsDark.lightningGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.lightningGold,
        secondary: AppColorsDark.textPrimary,
        surface: AppColorsDark.surface,
        error: AppColorsDark.error,
        onPrimary: Colors.black,
        onSurface: AppColorsDark.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsDark.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColorsDark.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColorsDark.textPrimary, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColorsDark.border, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          backgroundColor: AppColorsDark.textPrimary,
          foregroundColor: AppColorsDark.background,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          foregroundColor: AppColorsDark.textPrimary,
          side: const BorderSide(color: AppColorsDark.border, width: 1.0),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
