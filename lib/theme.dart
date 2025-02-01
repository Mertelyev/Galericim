import 'package:flutter/material.dart';

class AppTheme {
  // Ana renkler
  static const Color primaryNavy = Color(0xFF1B264F); // Koyu lacivert
  static const Color secondaryGrey = Color(0xFF576275); // Orta gri
  static const Color backgroundLight =
      Color(0xFFF5F6F9); // Açık arka plan rengi
  static const Color backgroundDark = Color(0xFF121212); // Koyu arka plan rengi

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight, // Arka plan rengi eklendi
      colorScheme: ColorScheme.light(
        primary: primaryNavy,
        onPrimary: Colors.white,
        secondary: secondaryGrey,
        onSecondary: Colors.white,
        surface: Colors.white,
        background: backgroundLight,
        primaryContainer: const Color(0xFFE6E9F0), // Açık lacivert tonu
        onPrimaryContainer: primaryNavy,
        secondaryContainer: Colors.grey[200]!,
        onSecondaryContainer: secondaryGrey,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 65,
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.15),
        surfaceTintColor: Colors.white,
        indicatorColor: primaryNavy.withOpacity(0.15),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryNavy);
          }
          return IconThemeData(color: secondaryGrey);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color: primaryNavy,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            );
          }
          return TextStyle(
            color: secondaryGrey,
            fontWeight: FontWeight.normal,
            fontSize: 13,
          );
        }),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        prefixIconColor: secondaryGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark, // Arka plan rengi eklendi
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF3B4B80), // Daha açık lacivert
        onPrimary: Colors.white,
        secondary: Colors.grey[400]!,
        onSecondary: Colors.white,
        surface: const Color(0xFF1A1B1E),
        background: backgroundDark,
        primaryContainer: const Color(0xFF2A3B6E), // Orta lacivert
        onPrimaryContainer: Colors.white,
        secondaryContainer: const Color(0xFF2A2B2F),
        onSecondaryContainer: Colors.grey[300]!,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF1A1B1E),
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 65,
        backgroundColor: const Color(0xFF1A1B1E),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: const Color(0xFF1A1B1E),
        indicatorColor: const Color(0xFF3B4B80).withOpacity(0.2),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return IconThemeData(color: Colors.grey[400]);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            );
          }
          return TextStyle(
            color: Colors.grey[400],
            fontWeight: FontWeight.normal,
            fontSize: 13,
          );
        }),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1A1B1E),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        backgroundColor: const Color(0xFF3B4B80),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2B2F),
        prefixIconColor: Colors.grey[400],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
