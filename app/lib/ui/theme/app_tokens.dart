import 'dart:ui';

abstract final class AppColors {
  static const yellow = Color(0xffffeb3b);
  static const amber = Color(0xffffc107);
  static const orange = Color(0xffffa726);
  static const linkLight = Color(0xffa16207);
  static const linkDark = amber;
  static const errorLight = Color(0xffb3261e);
  static const errorDark = Color(0xfff2b8b5);
  static const white = Color(0xffffffff);
  static const neutral50 = Color(0xfffafafa);
  static const neutral100 = Color(0xfff5f5f5);
  static const neutral200 = Color(0xffe5e5e5);
  static const neutral300 = Color(0xffd4d4d4);
  static const neutral400 = Color(0xffa3a3a3);
  static const neutral500 = Color(0xff737373);
  static const neutral600 = Color(0xff525252);
  static const neutral700 = Color(0xff404040);
  static const neutral800 = Color(0xff262626);
  static const neutral900 = Color(0xff171717);
}

abstract final class AppRadius {
  static const sheet = 16.0;
  static const card = 12.0;
  static const button = 10.0;
  static const field = 8.0;
  static const pill = 999.0;
}

abstract final class AppSpacing {
  static const grid = 4.0;
  static const screenPadding = 16.0;
  static const screenPaddingLarge = 20.0;
  static const cardPadding = 12.0;
  static const cardPaddingLarge = 16.0;
}
