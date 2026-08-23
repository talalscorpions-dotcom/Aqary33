import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AQARY brand palette — matches the HTML mockup and pitch materials.
class AppColors {
  AppColors._();

  static const teal = Color(0xFF0F4C4A);
  static const tealDark = Color(0xFF0A3634);
  static const tealTint = Color(0xFFEAF3F1);
  static const terra = Color(0xFFC97B4A);
  static const gold = Color(0xFFD4A24C);
  static const ink = Color(0xFF1B2523);
  static const mute = Color(0xFF6E7C79);
  static const line = Color(0xFFE4E1DA);
  static const bg = Color(0xFFF5F2EC);
  static const card = Color(0xFFFFFFFF);
  static const success = teal;
  static const danger = Color(0xFFB23B3B);
}

class AppTextStyles {
  AppTextStyles._();

  // Headings use Fraunces (serif) to match the brand wordmark.
  static TextStyle heading = GoogleFonts.fraunces(
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Body/UI text uses Plus Jakarta Sans, matching the mockup.
  static TextStyle body = GoogleFonts.plusJakartaSans(
    color: AppColors.ink,
  );

  static TextStyle kicker = GoogleFonts.plusJakartaSans(
    fontWeight: FontWeight.w800,
    fontSize: 11,
    letterSpacing: 0.6,
    color: AppColors.terra,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.terra,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTextStyles.heading.copyWith(fontSize: 24),
        headlineSmall: AppTextStyles.heading.copyWith(fontSize: 20),
        titleMedium: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
        bodyMedium: AppTextStyles.body.copyWith(fontSize: 13.5, color: AppColors.mute),
        labelLarge: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: AppTextStyles.heading.copyWith(fontSize: 19),
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terra,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tealDark,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.line, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
      ),
    );
  }
}
