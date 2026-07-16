import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotionTheme {
  // ============================================================
  // magic_black design tokens (ported from the web app's index.html).
  // NOTE: this class keeps its original member NAMES for source
  // compatibility, but every value now points at the magic_black
  // palette. The app is dark-only; the "light" constants resolve to
  // the same dark tokens so any `isDark ? dark : light` branch is safe.
  // ============================================================

  // Canvas
  static const Color ink = Color(0xFF0A1320); // near-black navy
  static const Color ink2 = Color(0xFF0D1B2B); // lifted canvas
  static const Color panel = Color(0xFF111F33); // solid glass fallback
  static const Color panelElevated = Color(0xFF16263E);

  // Accent (green -> lime gradient)
  static const Color green = Color(0xFF7CB342);
  static const Color lime = Color(0xFFA8CF38);
  static const Color limePale = Color(0xFFCDE9A2);

  // Text "fog" greys on navy
  static const Color white = Color(0xFFF4F8FE); // headings
  static const Color fog = Color(0xFFC5D2E2); // body
  static const Color fog2 = Color(0xFF8497AE); // muted
  static const Color borderSoft = Color(0x14C5D2E2); // rgba(197,210,226,.08)

  static const LinearGradient grad = LinearGradient(
    colors: [green, lime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- Compatibility aliases (repointed to magic_black) ----

  // Light mode names -> dark tokens (dark-only app)
  static const Color primaryBlack = white; // now primary (light) text
  static const Color backgroundOffWhite = ink;
  static const Color sidebarColor = ink2;
  static const Color dividerColor = Color(0xFF22344B);
  static const Color textGray = fog2;

  // Dark mode names
  static const Color darkBackground = ink;
  static const Color darkSurface = panel;
  static const Color darkSurfaceElevated = panelElevated;
  static const Color darkSidebar = ink2;
  static const Color darkDivider = Color(0xFF22344B);
  static const Color darkTextPrimary = white;
  static const Color darkTextSecondary = fog2;
  static const Color darkTextMuted = Color(0xFF5C6E86);

  // Primary accent is now lime; secondary content-type accents kept
  static const Color accentPurple = lime;
  static const Color accentPurpleLight = limePale;
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentPinkLight = Color(0xFFF472B6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentBlueLight = Color(0xFF60A5FA);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanLight = Color(0xFF22D3EE);
  static const Color accentGreen = green;
  static const Color accentGreenLight = lime;
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentRed = Color(0xFFEF4444);

  static const Color darkAccentPrimary = lime;
  static const Color darkAccentSecondary = green;
  static const Color darkAccentTertiary = limePale;

  // Gradient presets (primary = green->lime)
  static const LinearGradient primaryGradient = grad;

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [green, lime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF97316), lime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark theme specific gradients
  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [panel, ink2],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [panelElevated, panel],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow colors
  static Color glowPurple = lime.withValues(alpha: 0.3);
  static Color glowPink = lime.withValues(alpha: 0.22);
  static Color glowBlue = green.withValues(alpha: 0.25);

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: primaryColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: primaryColor,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        color: primaryColor,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
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
        onPrimary: ink,
        primaryContainer: Color(0xFF1F2E12),
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
            return ink;
          }),
          overlayColor: WidgetStateProperty.all(ink.withValues(alpha: 0.12)),
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
        foregroundColor: ink,
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
        circularTrackColor: Color(0xFF1F2E12),
        linearTrackColor: Color(0xFF1F2E12),
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
