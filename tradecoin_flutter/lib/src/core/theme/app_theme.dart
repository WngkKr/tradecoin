import 'package:flutter/material.dart';

class AppTheme {
  // Professional Trading Platform Colors
  static const Color primaryBlue = Color(0xFF1B365D);      // Deep professional blue
  static const Color accentBlue = Color(0xFF3B82F6);       // Bright blue for highlights
  static const Color successGreen = Color(0xFF16A34A);     // Professional green for gains
  static const Color dangerRed = Color(0xFFDC2626);        // Professional red for losses
  static const Color warningOrange = Color(0xFFF59E0B);    // Orange for warnings
  static const Color neutralGray = Color(0xFF6B7280);      // Neutral gray for text
  
  static const Color backgroundDark = Color(0xFF0F1419);   // Very dark background
  static const Color surfaceDark = Color(0xFF1A202C);      // Card surfaces
  static const Color cardDark = Color(0xFF2D3748);         // Card backgrounds
  static const Color borderColor = Color(0xFF374151);      // Subtle borders
  
  // Professional Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: accentBlue,
    secondary: primaryBlue,
    tertiary: successGreen,
    surface: surfaceDark,
    background: backgroundDark,
    error: dangerRed,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
  );
  
  // Light Color Scheme (for future use)
  static const ColorScheme colorScheme = ColorScheme.light(
    primary: accentBlue,
    secondary: primaryBlue,
    tertiary: successGreen,
    surface: Colors.white,
    background: Color(0xFFF8FAFC),
  );
  
  // AppBar 테마
  static const AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: accentBlue),
  );
  
  // Professional Navigation Theme
  static const BottomNavigationBarThemeData bottomNavigationBarTheme = 
    BottomNavigationBarThemeData(
    backgroundColor: surfaceDark,
    selectedItemColor: accentBlue,
    unselectedItemColor: neutralGray,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  );
  
  // Professional Button Theme
  static final ElevatedButtonThemeData elevatedButtonTheme = 
    ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: accentBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  
  // 카드 테마
  static final CardThemeData cardTheme = CardThemeData(
    color: surfaceDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    ),
  );
  
  // Professional Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, primaryBlue],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F1419), // Very dark
      Color(0xFF1A202C), // Dark surface
      Color(0xFF2D3748), // Slightly lighter
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x0A3B82F6), // Subtle blue tint
      Color(0x051B365D), // Very subtle dark blue
    ],
  );
  
  // 텍스트 스타일
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Colors.white,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: Color(0xFFE2E8F0),
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: Color(0xFF94A3B8),
  );
  
  // Professional Subtle Glow Effect
  static BoxShadow subtleGlow(Color color, {double blurRadius = 4}) {
    return BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: blurRadius,
      spreadRadius: 0,
    );
  }
  
  // 글래스모피즘 효과 (투명도 값 안전하게 조정)
  static BoxDecoration glassmorphism({
    Color? color,
    double borderRadius = 20,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color ?? const Color(0x1A1E293B), // surfaceDark with 10% opacity
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: const Color(0x33FFFFFF), // white with 20% opacity
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0x1A000000), // black with 10% opacity
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}