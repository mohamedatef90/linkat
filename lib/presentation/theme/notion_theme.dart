import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotionTheme {
  static const Color primaryBlack = Color(0xFF37352F);
  static const Color backgroundOffWhite = Color(
    0xFFFFFFFF,
  ); // Notion uses pure white or very light gray
  static const Color sidebarColor = Color(0xFFF7F7F5);
  static const Color dividerColor = Color(0xFFE9E9E8);
  static const Color textGray = Color(0xFF787774);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundOffWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        surface: backgroundOffWhite,
        onSurface: primaryBlack,
        secondary: textGray,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          color: primaryBlack,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          color: primaryBlack,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          color: primaryBlack,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: primaryBlack,
          fontSize: 14,
          height: 1.5,
        ),
        labelSmall: GoogleFonts.inter(
          color: textGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primaryBlack),
        titleTextStyle: GoogleFonts.inter(
          color: primaryBlack,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: backgroundOffWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: primaryBlack, size: 20),
    );
  }
}
