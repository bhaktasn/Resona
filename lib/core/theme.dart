import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppConstants.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppConstants.primaryTeal,
      secondary: AppConstants.accentBlue,
      surface: AppConstants.cardDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppConstants.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: AppConstants.textPrimary),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppConstants.textPrimary, fontSize: 48, fontWeight: FontWeight.w300),
      headlineMedium: TextStyle(color: AppConstants.textPrimary, fontSize: 32, fontWeight: FontWeight.w300),
      titleLarge: TextStyle(color: AppConstants.textPrimary, fontSize: 20, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: AppConstants.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: AppConstants.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: AppConstants.textSecondary, fontSize: 14),
      labelLarge: TextStyle(color: AppConstants.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primaryTeal,
        side: const BorderSide(color: AppConstants.primaryTeal),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),
  );
}
