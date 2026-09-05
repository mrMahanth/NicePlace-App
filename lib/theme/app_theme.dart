import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// All brand colors in one place. If the brand palette ever changes,
// this is the only file you need to touch.
class AppColors {
  static const Color primary = Color(0xFFFF6F5E); // CTAs, price tags, highlights
  static const Color background = Color(0xFFF2FAFC); // screens, cards
  static const Color accent = Color(0xFF1D3FD6); // links, secondary buttons, active tab
  static const Color textPrimary = Color(0xFF0F1B2D);
  static const Color textMuted = Color(0xFF5C6B7A);
  static const Color cardBorder = Color(0xFFDDEBF0);
  static const Color success = Color(0xFF2AA876); // use sparingly
  static const Color searchStripBackground = Color(0xFFFFF1EF); // pale tint of primary, for the search strip
}

class AppTheme {
  static ThemeData get lightTheme {
    final headingFont = GoogleFonts.poppins();
    final bodyFont = GoogleFonts.inter();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.background,
        error: const Color(0xFFD64545),
      ),

      textTheme: TextTheme(
        // Headings — Poppins, bold, primary text color
        displayLarge: headingFont.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: headingFont.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineLarge: headingFont.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: headingFont.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: headingFont.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        // Body — Inter, regular, readable
        bodyLarge: bodyFont.copyWith(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: bodyFont.copyWith(fontSize: 14, color: AppColors.textPrimary),
        bodySmall: bodyFont.copyWith(fontSize: 12, color: AppColors.textMuted),
        labelLarge: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: headingFont.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: bodyFont.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          textStyle: bodyFont.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: bodyFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: bodyFont.copyWith(color: AppColors.textMuted),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: bodyFont.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: bodyFont.copyWith(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        labelStyle: bodyFont.copyWith(fontSize: 12, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
      ),
    );
  }
}