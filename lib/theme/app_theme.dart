import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    color: AppTheme.darkText,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppTheme.darkText,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppTheme.darkText,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppTheme.darkText,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppTheme.mutedText,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 12.5,
    height: 1.4,
    color: AppTheme.mutedText,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10.5,
    color: AppTheme.mutedText,
  );

  static const TextStyle button = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle input = TextStyle(
    fontSize: 14,
    color: AppTheme.darkText,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 13,
    color: AppTheme.mutedText,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
  );
}

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF5B5FEF);
  static const Color darkText = Color(0xFF171A2B);
  static const Color mutedText = Color(0xFF8A8FA3);
  static const Color background = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE8E8F2);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),

    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.pageTitle,
      headlineMedium: AppTextStyles.sectionTitle,
      titleMedium: AppTextStyles.cardTitle,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.secondary,
      labelLarge: AppTextStyles.button,
      labelSmall: AppTextStyles.caption,
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: AppTextStyles.inputHint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primary,
          width: 1.3,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button,
        elevation: 0,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        textStyle: AppTextStyles.button,
        side: const BorderSide(
          color: primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}