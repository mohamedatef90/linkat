import 'package:flutter/material.dart';

/// Glass theme configuration for the app
class GlassTheme {
  // Vibrant gradient colors
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryPink = Color(0xFFEC4899);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color primaryGreen = Color(0xFFD4F933);
  static const Color darkOlive = Color(0xFF1A2F1A);

  // Glass effect parameters
  static const double glassOpacity = 0.15;
  static const double glassBorderOpacity = 0.2;
  static const double glassBlur = 10.0;

  // Platform colors
  static const Map<String, Color> platformColors = {
    'facebook': Color(0xFF1877F2),
    'instagram': Color(0xFFE4405F),
    'twitter': Color(0xFF1DA1F2),
    'youtube': Color(0xFFFF0000),
    'other': Color(0xFF6B7280),
  };

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1B4B), // Deep purple
      Color(0xFF312E81), // Purple
      Color(0xFF1E40AF), // Blue
      Color(0xFF0F172A), // Dark blue
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(glassOpacity),
      Colors.white.withOpacity(glassOpacity * 0.5),
    ],
  );

  static LinearGradient getPlatformGradient(String platform) {
    final color = platformColors[platform] ?? platformColors['other']!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
    );
  }

  // Theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: primaryPink,
        surface: Color(0xFF1E293B),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryPurple.withOpacity(0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
}
