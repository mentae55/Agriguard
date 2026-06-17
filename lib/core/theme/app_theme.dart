import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: whiteColor,
      fontFamily: 'AbhayaLibre',
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        background: whiteColor,
        surface: whiteColor,
        error: redColor,
        onPrimary: whiteColor,
        onSecondary: blackColor,
        onBackground: blackColor,
        onSurface: blackColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: blackColor,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          fontFamily: 'AbhayaLibre',
        ),
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: blackColor, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'AbhayaLibre'),
        displayMedium: TextStyle(color: blackColor, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'AbhayaLibre'),
        bodyLarge: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.normal, fontFamily: 'AbhayaLibre'),
        bodyMedium: TextStyle(color: blackColor, fontSize: 14, fontWeight: FontWeight.normal, fontFamily: 'AbhayaLibre'),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'AbhayaLibre',
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        error: redColor,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onBackground: whiteColor,
        onSurface: whiteColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          fontFamily: 'AbhayaLibre',
        ),
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'AbhayaLibre',
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'AbhayaLibre'),
        displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'AbhayaLibre'),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal, fontFamily: 'AbhayaLibre'),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal, fontFamily: 'AbhayaLibre'),
      ),
    );
  }
}
