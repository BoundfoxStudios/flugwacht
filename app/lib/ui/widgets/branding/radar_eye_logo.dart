import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Flugwacht radar eye, rendered from the vector master of the current
/// theme.
class RadarEyeLogo extends StatelessWidget {
  const RadarEyeLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    switch (Theme.of(context).brightness) {
      Brightness.light => 'assets/logo/logo-light.svg',
      Brightness.dark => 'assets/logo/logo-dark.svg',
    },
    width: size,
    height: size,
  );
}
