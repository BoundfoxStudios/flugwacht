import 'dart:math';
import 'dart:ui' show Tangent;

import 'package:material_ui/material_ui.dart';

import '../../theme/app_tokens.dart';
import '../map/map_visuals.dart';

/// Which of the two scenes the artwork shows.
enum RouteArtworkState {
  /// A flight the app is receiving: a solid flown trail and a pulsing position.
  live,

  /// The same route without a signal: every line dashed, the aircraft a
  /// silhouette. The picture the map itself draws over a coverage gap.
  resting,
}

/// A still of the map screen for the introduction: one route between two
/// airports, flown up to the aircraft and planned beyond it.
///
/// It is drawn rather than taken from the map, because the real map needs
/// tiles, a flight and a network the first start has none of.
class RouteArtwork extends StatelessWidget {
  const RouteArtwork({required this.state, super.key});

  final RouteArtworkState state;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _RouteScenePainter(
      colors: switch (Theme.of(context).brightness) {
        Brightness.light => _SceneColors.light,
        Brightness.dark => _SceneColors.dark,
      },
      state: state,
    ),
  );
}

class _RouteScenePainter extends CustomPainter {
  const _RouteScenePainter({required this.colors, required this.state});

  /// Where the two airports and the bow of the route sit, as fractions of the
  /// band, so the scene keeps its proportions on every screen width.
  static const _origin = Offset(0.16, 0.70);
  static const _destination = Offset(0.84, 0.32);
  static const _bow = Offset(0.5, 0.24);

  /// How much of the route lies behind the aircraft.
  static const _flownFraction = 0.55;

  static const _trailWidth = 2.5;
  static const _legWidth = 2.0;
  static const _legDash = 7.0;
  static const _legGap = 6.0;
  static const _airportDotRadius = 5.0;
  static const _positionDotRadius = 7.0;

  static const _ringWidth = 1.5;
  static const _innerRingRadius = 26.0;
  static const _outerRingRadius = 40.0;
  static const _innerRingOpacity = 0.5;
  static const _outerRingOpacity = 0.2;
  static const _ringDash = 4.0;

  /// Reads the same in both themes: the neutral scale mirrors around it.
  static const _restingRingColor = AppColors.neutral500;

  static const _silhouetteViewBox = 48.0;
  static const _silhouetteScale = 0.9;
  static const _contourWidth = 1.4;

  final _SceneColors colors;
  final RouteArtworkState state;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = _pointOf(_origin, size);
    final destination = _pointOf(_destination, size);
    final route = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(
        size.width * _bow.dx,
        size.height * _bow.dy,
        destination.dx,
        destination.dy,
      );
    final metric = route.computeMetrics().first;
    final flownLength = metric.length * _flownFraction;
    final aircraft = metric.getTangentForOffset(flownLength)!;

    _paintLeg(
      canvas,
      metric.extractPath(0, flownLength),
      color: state == RouteArtworkState.live ? colors.trail : colors.dimTrail,
      width: _trailWidth,
      isDashed: state == RouteArtworkState.resting,
    );
    _paintLeg(
      canvas,
      metric.extractPath(flownLength, metric.length),
      color: state == RouteArtworkState.live
          ? colors.dimTrail
          : colors.faintTrail,
      width: _legWidth,
      isDashed: true,
    );
    for (final airport in [origin, destination]) {
      canvas.drawCircle(
        airport,
        _airportDotRadius,
        Paint()..color = colors.trail,
      );
    }
    switch (state) {
      case RouteArtworkState.live:
        _paintPing(canvas, aircraft.position);
      case RouteArtworkState.resting:
        _paintRestingRings(canvas, aircraft.position);
        _paintSilhouette(canvas, aircraft);
    }
  }

  Offset _pointOf(Offset fraction, Size size) =>
      Offset(size.width * fraction.dx, size.height * fraction.dy);

  void _paintLeg(
    Canvas canvas,
    Path leg, {
    required Color color,
    required double width,
    required bool isDashed,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (!isDashed) {
      canvas.drawPath(leg, paint);
      return;
    }
    _paintDashed(canvas, leg, paint, dash: _legDash, gap: _legGap);
  }

  void _paintPing(Canvas canvas, Offset position) {
    for (final ring in const [
      (radius: _innerRingRadius, opacity: _innerRingOpacity),
      (radius: _outerRingRadius, opacity: _outerRingOpacity),
    ]) {
      canvas.drawCircle(
        position,
        ring.radius,
        Paint()
          ..color = AppColors.amber.withValues(alpha: ring.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
    }
    canvas.drawCircle(
      position,
      _positionDotRadius,
      Paint()..color = AppColors.amber,
    );
  }

  void _paintRestingRings(Canvas canvas, Offset position) {
    for (final ring in [
      (radius: _innerRingRadius, color: _restingRingColor),
      (radius: _outerRingRadius, color: colors.dimTrail),
    ]) {
      _paintDashed(
        canvas,
        Path()..addOval(Rect.fromCircle(center: position, radius: ring.radius)),
        Paint()
          ..color = ring.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
        dash: _ringDash,
        gap: _ringDash,
      );
    }
  }

  void _paintSilhouette(Canvas canvas, Tangent aircraft) {
    canvas
      ..save()
      ..translate(aircraft.position.dx, aircraft.position.dy)
      // The silhouette points up its view box, so the tangent turns into a
      // rotation by swapping the axes.
      ..rotate(atan2(aircraft.vector.dx, -aircraft.vector.dy))
      ..scale(_silhouetteScale)
      ..translate(-_silhouetteViewBox / 2, -_silhouetteViewBox / 2)
      ..drawPath(aircraftSilhouette, Paint()..color = colors.aircraftFill)
      ..drawPath(
        aircraftSilhouette,
        Paint()
          ..color = colors.aircraftContour
          ..style = PaintingStyle.stroke
          ..strokeWidth = _contourWidth,
      )
      ..restore();
  }

  void _paintDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += dash + gap) {
        canvas.drawPath(
          metric.extractPath(start, min(start + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteScenePainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.state != state;
}

/// The scene's three line weights, from the flown trail down to the faintest
/// leg. Resting shifts every line one step dimmer, which is what tells the two
/// scenes apart without a second palette.
enum _SceneColors {
  light(
    trail: AppColors.neutral700,
    dimTrail: AppColors.neutral400,
    faintTrail: AppColors.neutral300,
    aircraftFill: AppColors.neutral300,
    aircraftContour: AppColors.neutral500,
  ),
  dark(
    trail: AppColors.neutral300,
    dimTrail: AppColors.neutral600,
    faintTrail: AppColors.neutral700,
    aircraftFill: AppColors.neutral700,
    aircraftContour: AppColors.neutral400,
  );

  const _SceneColors({
    required this.trail,
    required this.dimTrail,
    required this.faintTrail,
    required this.aircraftFill,
    required this.aircraftContour,
  });

  final Color trail;
  final Color dimTrail;
  final Color faintTrail;
  final Color aircraftFill;
  final Color aircraftContour;
}
