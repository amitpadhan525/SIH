import 'package:flutter/material.dart';

class AppColors {
  // Artisan Earth & Terracotta Palette
  static const Color primary = Color(0xFFC85A32);
  static const Color primaryDark = Color(0xFFA64420);
  static const Color primaryLight = Color(0xFFFBECE6);

  static const Color background = Color(0xFFFBF9F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFEBE6DF);

  static const Color textPrimary = Color(0xFF1E2229);
  static const Color textSecondary = Color(0xFF5E6573);
  static const Color textMuted = Color(0xFF8C93A0);

  static const Color statusDraftBg = Color(0xFFFFF3E0);
  static const Color statusDraftText = Color(0xFFE65100);

  static const Color statusPublishedBg = Color(0xFFE8F5E9);
  static const Color statusPublishedText = Color(0xFF2E7D32);

  static const Color statusArchivedBg = Color(0xFFECEFF1);
  static const Color statusArchivedText = Color(0xFF546E7A);

  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }
}
