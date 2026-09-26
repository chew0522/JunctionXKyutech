import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF2B3A8F);
  static const primaryTint = Color(0xFFEEF0FA);
  static const primaryLine = Color(0xFFC9CEE8);
  static const nudge = Color(0xFF8A4B00);
  static const success = Color(0xFF1E6B3F);
  static const successFill = Color(0xFFE6F4EC);
  static const live = Color(0xFF2E8B57);
  static const danger = Color(0xFFA1331F);
  static const background = Color(0xFFF5F3EE);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1A1C20);
  static const textMuted = Color(0xFF5B5F66);
  static const line = Color(0xFFE3E0D8);
  static const lineSoft = Color(0xFFEFECE5);
  static const inputLine = Color(0xFFD6D2C8);
}

class AppRadius {
  static const button = 12.0;
  static const card = 20.0;
  static const pill = 999.0;
}

class AppText {
  static TextStyle display = GoogleFonts.bricolageGrotesque(
    fontSize: 30,
    height: 32 / 30,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static TextStyle title = GoogleFonts.bricolageGrotesque(
    fontSize: 21,
    height: 26 / 21,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static TextStyle cardTitle = GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static TextStyle appName = GoogleFonts.bricolageGrotesque(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static TextStyle body = GoogleFonts.figtree(
    fontSize: 15,
    height: 22 / 15,
    color: AppColors.text,
  );
  static TextStyle button = GoogleFonts.figtree(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );
  static TextStyle chip = GoogleFonts.figtree(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static TextStyle metaKey = GoogleFonts.figtree(
    fontSize: 13,
    height: 18 / 13,
    color: AppColors.textMuted,
  );
  static TextStyle metaValue = GoogleFonts.figtree(
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static TextStyle label = GoogleFonts.figtree(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
    color: AppColors.nudge,
  );
  static TextStyle timeDivider = GoogleFonts.figtree(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
    ).copyWith(surfaceTint: Colors.transparent),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.figtreeTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surface,
    ),
  );
}
