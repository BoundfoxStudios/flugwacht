import 'package:flutter/painting.dart';

abstract final class AppFontFamilies {
  static const bebasNeue = 'Bebas Neue';
  static const barlow = 'Barlow';
}

abstract final class AppTextStyles {
  static const timeLarge = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 54,
    height: 1,
    letterSpacing: 54 * 0.025,
  );

  static const timeMedium = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 40,
    height: 1,
    letterSpacing: 40 * 0.025,
  );

  static const screenTitle = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 36,
    height: 1,
    letterSpacing: 36 * 0.025,
  );

  static const screenTitleSmall = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 30,
    height: 1,
    letterSpacing: 30 * 0.025,
  );

  static const navigationTitle = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 22,
    height: 1,
    letterSpacing: 22 * 0.025,
  );

  static const buttonLabel = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 18,
    height: 1,
    letterSpacing: 18 * 0.05,
  );

  static const fieldLabel = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 14,
    height: 1,
    letterSpacing: 14 * 0.05,
  );

  static const tabLabel = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 13,
    height: 1,
    letterSpacing: 13 * 0.05,
  );

  static const sectionLabelLarge = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 14,
    height: 1,
    letterSpacing: 14 * 0.1,
  );

  static const sectionLabelMedium = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 13,
    height: 1,
    letterSpacing: 13 * 0.1,
  );

  static const sectionLabelSmall = TextStyle(
    fontFamily: AppFontFamilies.bebasNeue,
    fontSize: 12,
    height: 1,
    letterSpacing: 12 * 0.1,
  );

  static const bodyLarge = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 16,
  );

  static const bodyLargeEmphasis = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 15,
  );

  static const bodyEmphasis = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const accessory = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 14,
  );

  static const secondary = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 13,
  );

  static const secondaryEmphasis = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const small = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 12,
  );

  static const smallEmphasis = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const caption = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 11,
  );

  static const captionEmphasis = TextStyle(
    fontFamily: AppFontFamilies.barlow,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}
