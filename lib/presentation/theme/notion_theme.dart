import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotionTheme {
  // Light mode colors - Clean & Fresh
  static const Color primaryBlack = Color(0xFF1A1A2E);
  static const Color backgroundOffWhite = Color(0xFFFAFAFC);
  static const Color sidebarColor = Color(0xFFF0F0F5);
  static const Color dividerColor = Color(0xFFE8E8ED);
  static const Color textGray = Color(0xFF6B7280);

  // Modern Dark mode colors - Deep & Rich
  static const Color darkBackground = Color(0xFF0D0D12);
  static const Color darkSurface = Color(0xFF1A1A24);
  static const Color darkSurfaceElevated = Color(0xFF22222E);
  static const Color darkSidebar = Color(0xFF141420);
  static const Color darkDivider = Color(0xFF2E2E3A);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF8E8E9A);
  static const Color darkTextMuted = Color(0xFF5C5C6A);

  // Vibrant Accent colors
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFA78BFA);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPinkLight = Color(0xFFF472B6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentBlueLight = Color(0xFF60A5FA);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanLight = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentGreenLight = Color(0xFF34D399);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentRed = Color(0xFFEF4444);

  // Dark mode accent (keeping for compatibility)
  static const Color darkAccentPrimary = Color(0xFF8B5CF6);
  static const Color darkAccentSecondary = Color(0xFF3B82F6);
  static const Color darkAccentTertiary = Color(0xFFEC4899);

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [accentBlue, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [accentOrange, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark theme specific gradients
  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A24), Color(0xFF141420)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF22222E), Color(0xFF1A1A24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow colors for dark theme
  static Color glowPurple = accentPurple.withValues(alpha: 0.3);
  static Color glowPink = accentPink.withValues(alpha: 0.3);
  static Color glowBlue = accentBlue.withValues(alpha: 0.3);

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        color: secondaryColor,
        fontSize: 12,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        color: secondaryColor,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        color: primaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundOffWhite,
      colorScheme: const ColorScheme.light(
        primary: accentPurple,
        onPrimary: Colors.white,
        surface: backgroundOffWhite,
        onSurface: primaryBlack,
        secondary: accentPink,
        tertiary: accentBlue,
      ),
      textTheme: _buildTextTheme(primaryBlack, textGray),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: primaryBlack),
        titleTextStyle: GoogleFonts.inter(
          color: primaryBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      iconTheme: const IconThemeData(
        color: primaryBlack,
        size: 20,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPurple,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlack,
          side: const BorderSide(color: dividerColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.inter(color: textGray, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textGray, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentPurple, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sidebarColor,
        labelStyle: GoogleFonts.inter(color: primaryBlack, fontSize: 12),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryBlack,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF2D2250),
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceElevated,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        secondary: accentPink,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF4A1942),
        tertiary: accentCyan,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF0D3D45),
        error: accentRed,
        onError: Colors.white,
        outline: darkDivider,
        outlineVariant: Color(0xFF252532),
      ),
      textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkDivider.withValues(alpha: 0.5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary, size: 20),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentPurpleLight;
            }
            if (states.contains(WidgetState.disabled)) {
              return darkSurfaceElevated;
            }
            return accentPurple;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return darkTextMuted;
            }
            return Colors.white;
          }),
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(accentPurple.withValues(alpha: 0.4)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentPurpleLight;
            }
            if (states.contains(WidgetState.disabled)) {
              return darkTextMuted;
            }
            return accentPurple;
          }),
          overlayColor: WidgetStateProperty.all(accentPurple.withValues(alpha: 0.1)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 40)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentPurpleLight;
            }
            if (states.contains(WidgetState.disabled)) {
              return darkTextMuted;
            }
            return darkTextPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: accentPurple, width: 1.5);
            }
            return BorderSide(color: darkDivider.withValues(alpha: 0.8), width: 1.5);
          }),
          overlayColor: WidgetStateProperty.all(accentPurple.withValues(alpha: 0.1)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentPurple.withValues(alpha: 0.1);
            }
            return Colors.transparent;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 44)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentPurple;
            }
            return darkTextSecondary;
          }),
          overlayColor: WidgetStateProperty.all(accentPurple.withValues(alpha: 0.1)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 10,
        splashColor: Colors.white.withValues(alpha: 0.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceElevated,
        hintStyle: GoogleFonts.inter(color: darkTextMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkDivider.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkDivider.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentRed, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: darkDivider.withValues(alpha: 0.5)),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: darkTextSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: darkDivider.withValues(alpha: 0.5)),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceElevated,
        selectedColor: accentPurple.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: darkDivider.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkSurface,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: darkTextPrimary,
        iconColor: darkTextSecondary,
        tileColor: Colors.transparent,
        selectedTileColor: accentPurple.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          color: darkTextSecondary,
          fontSize: 13,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkDivider.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkDivider.withValues(alpha: 0.5)),
        ),
        textStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentPurple,
        circularTrackColor: Color(0xFF2D2250),
        linearTrackColor: Color(0xFF2D2250),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return darkTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPurple;
          }
          return darkSurfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return darkDivider;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPurple;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: darkDivider, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPurple;
          }
          return darkTextMuted;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentPurple,
        inactiveTrackColor: darkSurfaceElevated,
        thumbColor: Colors.white,
        overlayColor: accentPurple.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accentPurple,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: accentPurple,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkSurfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: darkDivider.withValues(alpha: 0.5)),
        ),
        textStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}
