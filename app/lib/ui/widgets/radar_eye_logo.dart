import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The Flugwacht radar eye, drawn from the vector master in
/// `assets/logo/logo-light.svg` and `assets/logo/logo-dark.svg`.
class RadarEyeLogo extends StatelessWidget {
  const RadarEyeLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final (outline, iris) = switch (Theme.of(context).brightness) {
      Brightness.light => (AppColors.neutral800, AppColors.neutral800),
      Brightness.dark => (AppColors.neutral50, AppColors.neutral700),
    };
    return CustomPaint(
      size: Size.square(size),
      painter: _RadarEyeLogoPainter(outline: outline, iris: iris),
    );
  }
}

class _RadarEyeLogoPainter extends CustomPainter {
  const _RadarEyeLogoPainter({required this.outline, required this.iris});

  static const _viewBoxSize = 48.0;
  static const _center = Offset(24, 24);

  final Color outline;
  final Color iris;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / _viewBoxSize)
      ..drawPath(
        Path()
          ..moveTo(4, 24)
          ..quadraticBezierTo(24, 6, 44, 24)
          ..quadraticBezierTo(24, 42, 4, 24)
          ..close(),
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawCircle(_center, 8.8, Paint()..color = iris)
      ..drawPath(
        Path()
          ..moveTo(24, 24)
          ..lineTo(24, 15.6)
          ..arcToPoint(
            const Offset(30.9, 20.3),
            radius: const Radius.circular(8.4),
          )
          ..close(),
        Paint()..color = AppColors.amber,
      )
      ..drawCircle(
        _center,
        4.8,
        Paint()
          ..color = AppColors.yellow.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      )
      ..drawCircle(_center, 1.5, Paint()..color = AppColors.yellow)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _RadarEyeLogoPainter oldDelegate) =>
      oldDelegate.outline != outline || oldDelegate.iris != iris;
}
