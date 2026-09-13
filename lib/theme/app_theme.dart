import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Builds the app's Material 3 theme from AppTokens.
/// Font family is Vazir (declared in pubspec.yaml).
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppTokens.primary,
    brightness: Brightness.light,
    primary: AppTokens.primary,
    surface: AppTokens.surface,
    error: AppTokens.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Vazir',
    scaffoldBackgroundColor: AppTokens.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppTokens.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazir',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppTokens.surface,
      indicatorColor: AppTokens.primary.withValues(alpha: 0.14),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Vazir',
          fontSize: 10.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? AppTokens.primary : AppTokens.onSurfaceVar,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppTokens.primary : AppTokens.onSurfaceVar,
          size: 22,
        );
      }),
    ),

    cardTheme: CardThemeData(
      color: AppTokens.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        side: const BorderSide(color: AppTokens.outlineVariant),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppTokens.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppTokens.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        borderSide: const BorderSide(color: AppTokens.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        borderSide: const BorderSide(color: AppTokens.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.rMd),
        borderSide: const BorderSide(color: AppTokens.primary, width: 2),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Vazir',
        color: AppTokens.onSurfaceVar,
        fontSize: 14,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rLg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTokens.primary,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppTokens.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rLg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}