
import 'package:flutter/material.dart';

/// App theme configuration with Ghibli-inspired design
class AppTheme {
  // Ghibli-inspired color palette
  static const Color primaryGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color primaryBlue = Color(0xFF42A5F5);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color cream = Color(0xFFFFF8E1);
  static const Color softBrown = Color(0xFF8D6E63);
  static const Color lightBrown = Color(0xFFD7CCC8);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color lavender = Color(0xFFE1BEE7);

  /// Light theme with Ghibli-inspired colors
  static ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryBlue,
        surface: Colors.white,
        background: cream,
        error: Color(0xFFE57373),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121),
        onBackground: Color(0xFF212121),
        onError: Colors.white,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkGreen,
        titleTextStyle: TextStyle(
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
        ),
        labelStyle: const TextStyle(color: darkGreen),
        hintStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF9E9E9E),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightGreen,
        selectedColor: primaryGreen,
        labelStyle: const TextStyle(color: darkGreen),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),

      // Snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGreen,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkGreen,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: darkGreen,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: darkGreen,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: darkGreen,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkGreen,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: darkGreen,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: darkGreen,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF212121),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF212121),
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF757575),
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: darkGreen,
        size: 24,
      ),
    );

  /// Custom gradients for backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      lightGreen,
      lightBlue,
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      cream,
    ],
  );

  /// Custom shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
  ];

  /// Border radius values
  static const double smallRadius = 8;
  static const double mediumRadius = 12;
  static const double largeRadius = 16;
  static const double extraLargeRadius = 20;
  static const double roundRadius = 28;
}
