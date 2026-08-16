import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Flugwacht lockup — radar eye and wordmark — rendered from the vector
/// master of the current theme.
class FlugwachtLockup extends StatelessWidget {
  const FlugwachtLockup({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(switch (Theme.of(context).brightness) {
        Brightness.light => 'assets/logo/lockup-light.svg',
        Brightness.dark => 'assets/logo/lockup-dark.svg',
      }, height: height);
}
