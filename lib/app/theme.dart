import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// WE PLAY color palette — dark neon Gen-Z aesthetic
class WePlayColors {
  WePlayColors._();

  static const Color background = Color(0xFF0A0A12);
  static const Color surface = Color(0xFF13131F);
  static const Color surfaceLight = Color(0xFF1C1C2E);
  static const Color primary = Color(0xFF7B61FF); // purple
  static const Color secondary = Color(0xFF00F5A0); // neon green
  static const Color energy = Color(0xFFFF3E6C); // hot pink
  static const Color amber = Color(0xFFFFB800); // amber/gold
  static const Color teal = Color(0xFF00E5FF); // teal
  static const Color textPrimary = Color(0xFFF2F2FF);
  static const Color textSecondary = Color(0xFF9090B0);
  static const Color cardBorder = Color(0x26FFFFFF); // 15% white
  static const Color cardGlow = Color(0x337B61FF); // purple glow
}

/// WE PLAY theme configuration
class WePlayTheme {
  WePlayTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WePlayColors.background,
      colorScheme: const ColorScheme.dark(
        primary: WePlayColors.primary,
        secondary: WePlayColors.secondary,
        surface: WePlayColors.surface,
        error: WePlayColors.energy,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: WePlayColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: WePlayColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: WePlayColors.cardBorder,
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: WePlayColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: WePlayColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WePlayColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WePlayColors.primary,
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: WePlayColors.surface,
        selectedItemColor: WePlayColors.primary,
        unselectedItemColor: WePlayColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: WePlayColors.textPrimary,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: WePlayColors.textPrimary,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: WePlayColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: WePlayColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: WePlayColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: WePlayColors.textPrimary,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: WePlayColors.textPrimary,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: WePlayColors.textPrimary,
        ),
        titleSmall: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: WePlayColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: WePlayColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: WePlayColors.textPrimary,
        ),
        bodySmall: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: WePlayColors.textSecondary,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: WePlayColors.textPrimary,
        ),
        labelMedium: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: WePlayColors.textSecondary,
        ),
        labelSmall: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: WePlayColors.textSecondary,
        ),
      ),
    );
  }
}
