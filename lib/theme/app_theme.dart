import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10.5,
  );

  static const TextStyle button = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle input = TextStyle(
    fontSize: 14,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: 13,
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

  // ============================================================
  // BRAND
  // ============================================================

  static const Color primary =
  Color(0xFF256D73);

  static const Color primaryDark =
  Color(0xFF1E555A);

  static const Color accent =
  Color(0xFFF2A65A);

  static const Color success =
  Color(0xFF4F8A68);

  static const Color error =
  Color(0xFFB85C5C);

  // ============================================================
  // LIGHT PALETTE
  // ============================================================

  static const Color darkText =
  Color(0xFF17252A);

  static const Color mutedText =
  Color(0xFF727B80);

  static const Color background =
  Color(0xFFF7F8F6);

  static const Color surface =
  Color(0xFFFFFFFF);

  static const Color surfaceVariant =
  Color(0xFFF0F3F1);

  static const Color border =
  Color(0xFFE4E7E5);

  // ============================================================
  // DARK PALETTE
  // ============================================================

  static const Color darkBackground =
  Color(0xFF0F1718);

  static const Color darkSurface =
  Color(0xFF182123);

  static const Color darkSurfaceVariant =
  Color(0xFF202B2D);

  static const Color darkBorder =
  Color(0xFF2E3A3C);

  static const Color darkPrimaryText =
  Color(0xFFF2F5F4);

  static const Color darkMutedText =
  Color(0xFFA2ACAA);

  static const Color darkPrimary =
  Color(0xFF5FAEB1);

  // ============================================================
  // COLOR SCHEMES
  // ============================================================

  static const ColorScheme _lightColorScheme =
  ColorScheme(
    brightness: Brightness.light,

    primary: primary,
    onPrimary: Colors.white,

    primaryContainer:
    Color(0xFFD7ECEB),
    onPrimaryContainer:
    Color(0xFF103C40),

    secondary: accent,
    onSecondary:
    Color(0xFF3D260E),

    secondaryContainer:
    Color(0xFFFFE1C2),
    onSecondaryContainer:
    Color(0xFF4A2D11),

    tertiary:
    Color(0xFF5E796E),
    onTertiary:
    Colors.white,

    tertiaryContainer:
    Color(0xFFDCE9E2),
    onTertiaryContainer:
    Color(0xFF263D34),

    error: error,
    onError:
    Colors.white,

    errorContainer:
    Color(0xFFF7DEDE),
    onErrorContainer:
    Color(0xFF652929),

    surface: surface,
    onSurface: darkText,

    surfaceContainerHighest:
    surfaceVariant,

    onSurfaceVariant:
    mutedText,

    outline:
    Color(0xFF9BA5A1),

    outlineVariant:
    border,

    shadow:
    Color(0x1F000000),

    scrim:
    Color(0x66000000),

    inverseSurface:
    Color(0xFF253133),

    onInverseSurface:
    Color(0xFFF4F7F5),

    inversePrimary:
    Color(0xFF79C0C2),

    surfaceTint:
    Colors.transparent,
  );

  static const ColorScheme _darkColorScheme =
  ColorScheme(
    brightness: Brightness.dark,

    primary: darkPrimary,
    onPrimary:
    Color(0xFF092E31),

    primaryContainer:
    Color(0xFF21484B),
    onPrimaryContainer:
    Color(0xFFC9ECEC),

    secondary: accent,
    onSecondary:
    Color(0xFF432A0E),

    secondaryContainer:
    Color(0xFF5A3A19),
    onSecondaryContainer:
    Color(0xFFFFDFC0),

    tertiary:
    Color(0xFF8AB4A3),
    onTertiary:
    Color(0xFF17382E),

    tertiaryContainer:
    Color(0xFF294A40),
    onTertiaryContainer:
    Color(0xFFC5E5D8),

    error:
    Color(0xFFFFB4AB),
    onError:
    Color(0xFF690005),

    errorContainer:
    Color(0xFF822323),
    onErrorContainer:
    Color(0xFFFFDAD6),

    surface: darkSurface,
    onSurface: darkPrimaryText,

    surfaceContainerHighest:
    darkSurfaceVariant,

    onSurfaceVariant:
    darkMutedText,

    outline:
    Color(0xFF778381),

    outlineVariant:
    darkBorder,

    shadow:
    Color(0xFF000000),

    scrim:
    Color(0xAA000000),

    inverseSurface:
    Color(0xFFDCE5E3),

    onInverseSurface:
    Color(0xFF1A2325),

    inversePrimary:
    primary,

    surfaceTint:
    Colors.transparent,
  );

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static final ThemeData lightTheme =
  ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    scaffoldBackgroundColor:
    background,

    colorScheme:
    _lightColorScheme,

    cardColor:
    surface,

    canvasColor:
    surface,

    dialogTheme:
    const DialogThemeData(
      backgroundColor:
      surface,
      surfaceTintColor:
      Colors.transparent,
    ),

    bottomSheetTheme:
    const BottomSheetThemeData(
      backgroundColor:
      surface,
      surfaceTintColor:
      Colors.transparent,
    ),

    textTheme:
    const TextTheme(
      headlineLarge:
      AppTextStyles.pageTitle,
      headlineMedium:
      AppTextStyles.sectionTitle,
      titleMedium:
      AppTextStyles.cardTitle,
      bodyLarge:
      AppTextStyles.body,
      bodyMedium:
      AppTextStyles.body,
      bodySmall:
      AppTextStyles.secondary,
      labelLarge:
      AppTextStyles.button,
      labelSmall:
      AppTextStyles.caption,
    ).apply(
      bodyColor:
      darkText,
      displayColor:
      darkText,
    ),

    appBarTheme:
    const AppBarTheme(
      backgroundColor:
      background,
      foregroundColor:
      darkText,
      surfaceTintColor:
      Colors.transparent,
      elevation: 0,
    ),

    dividerTheme:
    const DividerThemeData(
      color:
      border,
    ),

    iconTheme:
    const IconThemeData(
      color:
      darkText,
    ),

    listTileTheme:
    const ListTileThemeData(
      textColor:
      darkText,
      iconColor:
      darkText,
    ),

    inputDecorationTheme:
    InputDecorationTheme(
      hintStyle:
      AppTextStyles.inputHint.copyWith(
        color:
        mutedText,
      ),
      labelStyle:
      const TextStyle(
        color:
        mutedText,
      ),
      floatingLabelStyle:
      const TextStyle(
        color:
        primary,
      ),
      filled: true,
      fillColor:
      surface,
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          border,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          border,
        ),
      ),
      disabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          border,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          primary,
          width:
          1.3,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          error,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          error,
          width:
          1.3,
        ),
      ),
    ),

    elevatedButtonTheme:
    ElevatedButtonThemeData(
      style:
      ElevatedButton.styleFrom(
        backgroundColor:
        primary,
        foregroundColor:
        Colors.white,
        disabledBackgroundColor:
        border,
        disabledForegroundColor:
        mutedText,
        textStyle:
        AppTextStyles.button,
        elevation: 0,
        minimumSize:
        const Size(
          0,
          46,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    ),

    outlinedButtonTheme:
    OutlinedButtonThemeData(
      style:
      OutlinedButton.styleFrom(
        foregroundColor:
        primary,
        textStyle:
        AppTextStyles.button,
        side:
        const BorderSide(
          color:
          primary,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    ),

    textButtonTheme:
    TextButtonThemeData(
      style:
      TextButton.styleFrom(
        foregroundColor:
        primary,
      ),
    ),

    switchTheme:
    SwitchThemeData(
      thumbColor:
      WidgetStateProperty
          .resolveWith<Color?>(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return Colors.white;
          }

          return null;
        },
      ),
      trackColor:
      WidgetStateProperty
          .resolveWith<Color?>(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return primary;
          }

          return null;
        },
      ),
    ),

    snackBarTheme:
    const SnackBarThemeData(
      backgroundColor:
      Color(0xFF243638),
      contentTextStyle:
      TextStyle(
        color:
        Colors.white,
      ),
      behavior:
      SnackBarBehavior.floating,
    ),
  );

  // ============================================================
  // DARK THEME
  // ============================================================

  static final ThemeData darkTheme =
  ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    scaffoldBackgroundColor:
    darkBackground,

    colorScheme:
    _darkColorScheme,

    cardColor:
    darkSurface,

    canvasColor:
    darkSurface,

    dialogTheme:
    const DialogThemeData(
      backgroundColor:
      darkSurface,
      surfaceTintColor:
      Colors.transparent,
    ),

    bottomSheetTheme:
    const BottomSheetThemeData(
      backgroundColor:
      darkSurface,
      surfaceTintColor:
      Colors.transparent,
    ),

    textTheme:
    const TextTheme(
      headlineLarge:
      AppTextStyles.pageTitle,
      headlineMedium:
      AppTextStyles.sectionTitle,
      titleMedium:
      AppTextStyles.cardTitle,
      bodyLarge:
      AppTextStyles.body,
      bodyMedium:
      AppTextStyles.body,
      bodySmall:
      AppTextStyles.secondary,
      labelLarge:
      AppTextStyles.button,
      labelSmall:
      AppTextStyles.caption,
    ).apply(
      bodyColor:
      darkPrimaryText,
      displayColor:
      darkPrimaryText,
    ),

    appBarTheme:
    const AppBarTheme(
      backgroundColor:
      darkBackground,
      foregroundColor:
      darkPrimaryText,
      surfaceTintColor:
      Colors.transparent,
      elevation: 0,
    ),

    dividerTheme:
    const DividerThemeData(
      color:
      darkBorder,
    ),

    iconTheme:
    const IconThemeData(
      color:
      darkPrimaryText,
    ),

    listTileTheme:
    const ListTileThemeData(
      textColor:
      darkPrimaryText,
      iconColor:
      darkPrimaryText,
    ),

    inputDecorationTheme:
    InputDecorationTheme(
      hintStyle:
      AppTextStyles.inputHint.copyWith(
        color:
        darkMutedText,
      ),
      labelStyle:
      const TextStyle(
        color:
        darkMutedText,
      ),
      floatingLabelStyle:
      const TextStyle(
        color:
        darkPrimary,
      ),
      filled: true,
      fillColor:
      darkSurfaceVariant,
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          darkBorder,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          darkBorder,
        ),
      ),
      disabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          darkBorder,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          darkPrimary,
          width:
          1.3,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          Color(
            0xFFFFB4AB,
          ),
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        borderSide:
        const BorderSide(
          color:
          Color(
            0xFFFFB4AB,
          ),
          width:
          1.3,
        ),
      ),
    ),

    elevatedButtonTheme:
    ElevatedButtonThemeData(
      style:
      ElevatedButton.styleFrom(
        backgroundColor:
        darkPrimary,
        foregroundColor:
        const Color(
          0xFF092E31,
        ),
        disabledBackgroundColor:
        darkSurfaceVariant,
        disabledForegroundColor:
        darkMutedText,
        textStyle:
        AppTextStyles.button,
        elevation: 0,
        minimumSize:
        const Size(
          0,
          46,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    ),

    outlinedButtonTheme:
    OutlinedButtonThemeData(
      style:
      OutlinedButton.styleFrom(
        foregroundColor:
        darkPrimary,
        textStyle:
        AppTextStyles.button,
        side:
        const BorderSide(
          color:
          darkPrimary,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    ),

    textButtonTheme:
    TextButtonThemeData(
      style:
      TextButton.styleFrom(
        foregroundColor:
        darkPrimary,
      ),
    ),

    switchTheme:
    SwitchThemeData(
      thumbColor:
      WidgetStateProperty
          .resolveWith<Color?>(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return const Color(
              0xFF092E31,
            );
          }

          return null;
        },
      ),
      trackColor:
      WidgetStateProperty
          .resolveWith<Color?>(
            (
            Set<WidgetState> states,
            ) {
          if (states.contains(
            WidgetState.selected,
          )) {
            return darkPrimary;
          }

          return null;
        },
      ),
    ),

    snackBarTheme:
    const SnackBarThemeData(
      backgroundColor:
      Color(0xFF263234),
      contentTextStyle:
      TextStyle(
        color:
        darkPrimaryText,
      ),
      behavior:
      SnackBarBehavior.floating,
    ),
  );
}