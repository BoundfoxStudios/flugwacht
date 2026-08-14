import 'package:flutter/material.dart';

import 'app_tokens.dart';

ThemeData buildLightTheme() => _themeFrom(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.amber,
    onPrimary: AppColors.neutral800,
    secondary: AppColors.yellow,
    onSecondary: AppColors.neutral800,
    tertiary: AppColors.orange,
    onTertiary: AppColors.neutral800,
    error: AppColors.errorLight,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.neutral900,
    onSurfaceVariant: AppColors.neutral500,
    outline: AppColors.neutral200,
    outlineVariant: AppColors.neutral200,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.neutral50,
    surfaceContainer: AppColors.neutral100,
    surfaceContainerHigh: AppColors.neutral100,
    surfaceContainerHighest: AppColors.neutral100,
    inverseSurface: AppColors.neutral800,
    onInverseSurface: AppColors.neutral50,
  ),
  scaffoldBackground: AppColors.neutral50,
);

ThemeData buildDarkTheme() => _themeFrom(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.amber,
    onPrimary: AppColors.neutral800,
    secondary: AppColors.yellow,
    onSecondary: AppColors.neutral800,
    tertiary: AppColors.orange,
    onTertiary: AppColors.neutral800,
    error: AppColors.errorDark,
    onError: AppColors.neutral900,
    surface: AppColors.neutral800,
    onSurface: AppColors.neutral50,
    onSurfaceVariant: AppColors.neutral400,
    outline: AppColors.neutral700,
    outlineVariant: AppColors.neutral600,
    surfaceContainerLowest: AppColors.neutral900,
    surfaceContainerLow: AppColors.neutral900,
    surfaceContainer: AppColors.neutral800,
    surfaceContainerHigh: AppColors.neutral800,
    surfaceContainerHighest: AppColors.neutral800,
    inverseSurface: AppColors.neutral50,
    onInverseSurface: AppColors.neutral800,
  ),
  scaffoldBackground: AppColors.neutral900,
);

ThemeData _themeFrom({
  required ColorScheme colorScheme,
  required Color scaffoldBackground,
}) => ThemeData(
  colorScheme: colorScheme,
  scaffoldBackgroundColor: scaffoldBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: scaffoldBackground,
    foregroundColor: colorScheme.onSurface,
    centerTitle: true,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.amber,
    foregroundColor: AppColors.neutral800,
  ),
);
