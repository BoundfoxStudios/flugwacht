import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'app_tokens.dart';

ThemeData buildLightTheme() => _themeFrom(
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.amber,
    onPrimary: AppColors.neutral900,
    secondary: AppColors.yellow,
    onSecondary: AppColors.neutral900,
    tertiary: AppColors.orange,
    onTertiary: AppColors.neutral900,
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
  textTheme: _textThemeFrom(
    display: AppColors.neutral900,
    title: AppColors.neutral900,
    fieldLabel: AppColors.neutral700,
    sectionLabel: AppColors.neutral400,
    bodyLarge: AppColors.neutral800,
    body: AppColors.neutral700,
    secondary: AppColors.neutral500,
  ),
);

ThemeData buildDarkTheme() => _themeFrom(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.amber,
    onPrimary: AppColors.neutral900,
    secondary: AppColors.yellow,
    onSecondary: AppColors.neutral900,
    tertiary: AppColors.orange,
    onTertiary: AppColors.neutral900,
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
  textTheme: _textThemeFrom(
    display: AppColors.white,
    title: AppColors.neutral50,
    fieldLabel: AppColors.neutral400,
    sectionLabel: AppColors.neutral500,
    bodyLarge: AppColors.neutral50,
    body: AppColors.neutral300,
    secondary: AppColors.neutral400,
  ),
);

TextTheme _textThemeFrom({
  required Color display,
  required Color title,
  required Color fieldLabel,
  required Color sectionLabel,
  required Color bodyLarge,
  required Color body,
  required Color secondary,
}) => TextTheme(
  displayLarge: AppTextStyles.timeLarge.copyWith(color: display),
  displayMedium: AppTextStyles.timeMedium.copyWith(color: display),
  headlineLarge: AppTextStyles.screenTitle.copyWith(color: display),
  headlineMedium: AppTextStyles.screenTitleSmall.copyWith(color: display),
  titleLarge: AppTextStyles.navigationTitle.copyWith(color: title),
  labelLarge: AppTextStyles.fieldLabel.copyWith(color: fieldLabel),
  labelMedium: AppTextStyles.tabLabel.copyWith(color: fieldLabel),
  labelSmall: AppTextStyles.sectionLabelSmall.copyWith(color: sectionLabel),
  bodyLarge: AppTextStyles.bodyLarge.copyWith(color: bodyLarge),
  bodyMedium: AppTextStyles.body.copyWith(color: body),
  bodySmall: AppTextStyles.secondary.copyWith(color: secondary),
);

ThemeData _themeFrom({
  required ColorScheme colorScheme,
  required Color scaffoldBackground,
  required TextTheme textTheme,
}) => ThemeData(
  colorScheme: colorScheme,
  scaffoldBackgroundColor: scaffoldBackground,
  fontFamily: AppFontFamilies.barlow,
  textTheme: textTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: scaffoldBackground,
    foregroundColor: colorScheme.onSurface,
    centerTitle: true,
    titleTextStyle: textTheme.titleLarge,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.amber,
    foregroundColor: AppColors.neutral900,
  ),
);
