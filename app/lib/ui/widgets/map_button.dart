import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_tokens.dart';

/// The chrome of the buttons floating on the map: a 44×44 square carrying one
/// icon, on the map's own surface rather than the theme's.
class MapButton extends StatelessWidget {
  const MapButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
    super.key,
  });

  static const size = 44.0;
  static const gap = 10.0;

  static const _iconSize = 17.0;
  static const _lightShadow = BoxShadow(
    color: Color(0x12000000),
    offset: Offset(0, 4),
    blurRadius: 6,
    spreadRadius: -1,
  );

  final FaIconData icon;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground, shadows) = switch (Theme.of(
      context,
    ).brightness) {
      Brightness.light => (
        AppColors.white,
        AppColors.neutral200,
        AppColors.neutral700,
        const [_lightShadow],
      ),
      Brightness.dark => (
        AppColors.neutral800,
        AppColors.neutral700,
        AppColors.neutral300,
        const <BoxShadow>[],
      ),
    };
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: border),
            boxShadow: shadows,
          ),
          child: FaIcon(icon, size: _iconSize, color: foreground),
        ),
      ),
    );
  }
}
