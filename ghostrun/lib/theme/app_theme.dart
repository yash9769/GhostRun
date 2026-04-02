import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Background Colors
  static const Color bgPrimary = Color(0xFF0D0F1A);
  static const Color bgSecondary = Color(0xFF11141F);
  static const Color bgCard = Color(0xFF181B27);
  static const Color bgCardLight = Color(0xFF1E2132);
  static const Color bgSurface = Color(0xFF141726);

  // Accent Colors
  static const Color accentBlue = Color(0xFF4D8EFF);
  static const Color accentBlueDim = Color(0xFF2A5CC8);
  static const Color accentBluePale = Color(0xFFB8CCFF);
  static const Color accentGreen = Color(0xFF00D26A);
  static const Color accentGreenDim = Color(0xFF00A854);
  static const Color accentRed = Color(0xFFFF4444);
  static const Color accentRedDim = Color(0xFFCC2222);
  static const Color accentOrange = Color(0xFFFF9D00);
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentLavender = Color(0xFFB8C5FF);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8CC);
  static const Color textMuted = Color(0xFF5A6478);
  static const Color textDim = Color(0xFF3A4258);

  // Border Colors
  static const Color borderColor = Color(0xFF1E2436);
  static const Color borderLight = Color(0xFF252B3D);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentBluePale,
        surface: bgCard,
        error: accentRed,
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        titleTextStyle: GoogleFonts.rajdhani(
          color: accentBlue,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // Text Styles
  static TextStyle get headingXL => GoogleFonts.rajdhani(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get headingL => GoogleFonts.rajdhani(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get headingM => GoogleFonts.rajdhani(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get headingS => GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyM => GoogleFonts.rajdhani(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyS => GoogleFonts.rajdhani(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  static TextStyle get labelXS => GoogleFonts.rajdhani(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 1.5,
      );

  static TextStyle get mono => GoogleFonts.sourceCodePro(
        fontSize: 12,
        color: textSecondary,
        height: 1.6,
      );

  static TextStyle get monoMuted => GoogleFonts.sourceCodePro(
        fontSize: 11,
        color: textMuted,
        height: 1.6,
      );
}
