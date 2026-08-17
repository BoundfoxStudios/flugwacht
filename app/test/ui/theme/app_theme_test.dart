import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    group('$name theme', () {
      test('fills the destructive surface darker than the icon on it', () {
        final colorScheme = theme.colorScheme;
        expect(
          colorScheme.error.computeLuminance(),
          lessThan(colorScheme.onError.computeLuminance()),
        );
      });

      test('keeps the destructive icon legible against its fill', () {
        final colorScheme = theme.colorScheme;
        expect(
          _contrastRatio(colorScheme.error, colorScheme.onError),
          greaterThanOrEqualTo(3),
        );
      });

      test('keeps the snackbar action legible on the inverse surface', () {
        final colorScheme = theme.colorScheme;
        expect(
          _contrastRatio(
            colorScheme.inverseSurface,
            colorScheme.inversePrimary,
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    });
  }
}
