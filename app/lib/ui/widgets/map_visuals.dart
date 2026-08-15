import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../domain/fix.dart';
import '../../domain/flight_route.dart';
import '../../domain/flight_state.dart';
import '../../domain/source_id.dart';
import '../../domain/trail_point.dart';
import '../theme/app_tokens.dart';

/// Zoom for a flight whose points are one spot on the globe — a flight without
/// a route, or one whose trail has not moved away from it yet.
const flightRegionalZoom = 6.0;

/// Degrees the points have to span before fitting them beats the fixed zoom.
const _minimumFitSpan = 0.01;

/// The points a flight has to keep in view: the route ends, the flown trail
/// and the latest position.
List<LatLng> flightFocusPoints({
  required FixPosition position,
  required FlightRoute? route,
  required List<TrailPoint> trail,
}) => [
  if (route != null) ...[
    LatLng(route.origin.latitude, route.origin.longitude),
    LatLng(route.destination.latitude, route.destination.longitude),
  ],
  for (final point in trail) LatLng(point.latitude, point.longitude),
  LatLng(position.latitude, position.longitude),
];

/// Null whenever the points are one spot on the globe: fitting a bounds
/// without an area blows the zoom up to infinity.
CameraFit? cameraFitFor(List<LatLng> points, {required EdgeInsets padding}) {
  if (points.length < 2) {
    return null;
  }
  final bounds = LatLngBounds.fromPoints(points);
  final span = max(bounds.north - bounds.south, bounds.east - bounds.west);
  return span < _minimumFitSpan
      ? null
      : CameraFit.bounds(bounds: bounds, padding: padding);
}

Widget mapTiles({required MapColors colors, TileProvider? tileProvider}) {
  final tiles = TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'de.boundfoxstudios.flugwacht',
    // A fresh instance per build is what TileLayer does by default; it takes
    // ownership and disposes whatever it is handed.
    tileProvider: tileProvider ?? NetworkTileProvider(),
  );
  return colors.tileFilter == null
      ? tiles
      : ColorFiltered(colorFilter: colors.tileFilter!, child: tiles);
}

/// The sources that stitched the trail together.
Set<SourceId> trailSourceIds(List<TrailPoint> trail) => {
  for (final point in trail) point.sourceId,
};

/// Whether the trail holds points of several sources and therefore becomes the
/// source comparison: colored per source, legended, explained in the peek.
bool comparesSources(List<TrailPoint> trail) =>
    trailSourceIds(trail).length > 1;

/// The flown trail up to the aircraft and the dashed leg towards the
/// destination.
List<Polyline<Object>> flightPolylines({
  required MapColors colors,
  required FlightState state,
  required FlightRoute? route,
  required List<TrailPoint> trail,
  required LatLng aircraft,
  required double trailWidth,
  required double plannedLegWidth,
  required List<double> plannedLegDash,
}) => [
  if (trail.isNotEmpty)
    if (comparesSources(trail))
      ..._sourceSegments(
        colors: colors,
        trail: trail,
        aircraft: aircraft,
        width: trailWidth,
      )
    else
      Polyline(
        points: [
          for (final point in trail) LatLng(point.latitude, point.longitude),
          aircraft,
        ],
        color: colors.trail,
        strokeWidth: trailWidth,
      ),
  if (route != null)
    Polyline(
      points: [
        aircraft,
        LatLng(route.destination.latitude, route.destination.longitude),
      ],
      color: state == FlightState.noSignal
          ? colors.plannedLegNoSignal
          : colors.plannedLeg,
      strokeWidth: plannedLegWidth,
      pattern: StrokePattern.dashed(segments: plannedLegDash),
    ),
];

/// One line per run of points from the same source; neighbours share their
/// boundary point so the trail stays gapless, and the aircraft extends the
/// last run.
List<Polyline<Object>> _sourceSegments({
  required MapColors colors,
  required List<TrailPoint> trail,
  required LatLng aircraft,
  required double width,
}) {
  final segments = <Polyline<Object>>[];
  var sourceId = trail.first.sourceId;
  var points = <LatLng>[];
  for (final point in trail) {
    if (point.sourceId != sourceId) {
      segments.add(
        Polyline(
          points: points,
          color: colors.trailOf(sourceId),
          strokeWidth: width,
        ),
      );
      points = [points.last];
      sourceId = point.sourceId;
    }
    points.add(LatLng(point.latitude, point.longitude));
  }
  points.add(aircraft);
  return [
    ...segments,
    Polyline(
      points: points,
      color: colors.trailOf(sourceId),
      strokeWidth: width,
    ),
  ];
}

Marker airportMarker({
  required MapColors colors,
  required RouteAirport airport,
  required double dotRadius,
  required TextStyle labelStyle,
}) => Marker(
  point: LatLng(airport.latitude, airport.longitude),
  width: _airportMarkerWidth,
  height: _airportMarkerHeight,
  child: Stack(
    children: [
      Positioned(
        left: _airportMarkerWidth / 2 - dotRadius,
        top: _airportMarkerHeight / 2 - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.airportDot,
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        left: _airportMarkerWidth / 2 + _airportLabelOffset,
        top: 0,
        bottom: 0,
        child: Center(
          child: Text(
            airport.iataCode ?? airport.icaoCode,
            style: labelStyle.copyWith(color: colors.airportLabel),
          ),
        ),
      ),
    ],
  ),
);

const _airportMarkerWidth = 96.0;
const _airportMarkerHeight = 24.0;
const _airportLabelOffset = 8.0;

/// Inverts and hue-rotates the raster tiles so the light OSM style carries the
/// dark theme until the reduced style of M11 replaces it.
const _darkTileFilter = ColorFilter.matrix(<double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

enum MapColors {
  light(
    mapBackground: AppColors.white,
    trail: AppColors.neutral700,
    airplanesTrail: AppColors.neutral500,
    plannedLeg: AppColors.neutral400,
    plannedLegNoSignal: AppColors.neutral300,
    airportDot: AppColors.neutral700,
    airportLabel: AppColors.neutral500,
    aircraftFill: AppColors.amber,
    aircraftContour: AppColors.neutral800,
    noSignalFill: AppColors.neutral300,
    noSignalContour: AppColors.neutral500,
    pingOpacity: 0.5,
  ),
  dark(
    mapBackground: AppColors.neutral800,
    trail: AppColors.neutral300,
    airplanesTrail: AppColors.neutral300,
    plannedLeg: AppColors.neutral500,
    plannedLegNoSignal: AppColors.neutral600,
    airportDot: AppColors.neutral300,
    airportLabel: AppColors.neutral400,
    aircraftFill: AppColors.amber,
    aircraftContour: AppColors.neutral900,
    noSignalFill: AppColors.neutral600,
    noSignalContour: AppColors.neutral400,
    pingOpacity: 0.55,
    tileFilter: _darkTileFilter,
  );

  const MapColors({
    required this.mapBackground,
    required this.trail,
    required this.airplanesTrail,
    required this.plannedLeg,
    required this.plannedLegNoSignal,
    required this.airportDot,
    required this.airportLabel,
    required this.aircraftFill,
    required this.aircraftContour,
    required this.noSignalFill,
    required this.noSignalContour,
    required this.pingOpacity,
    this.tileFilter,
  });

  static MapColors of(BuildContext context) =>
      switch (Theme.of(context).brightness) {
        Brightness.light => MapColors.light,
        Brightness.dark => MapColors.dark,
      };

  /// The trail color of a source, telling the segments of a comparison apart;
  /// only airplanes.live needs a color of its own per theme.
  Color trailOf(SourceId sourceId) => switch (sourceId) {
    SourceId.adsblol => AppColors.amber,
    SourceId.adsbfi => AppColors.orange,
    SourceId.airplanes => airplanesTrail,
  };

  final Color mapBackground;
  final Color trail;
  final Color airplanesTrail;
  final Color plannedLeg;
  final Color plannedLegNoSignal;
  final Color airportDot;
  final Color airportLabel;
  final Color aircraftFill;
  final Color aircraftContour;
  final Color noSignalFill;
  final Color noSignalContour;
  final double pingOpacity;
  final ColorFilter? tileFilter;
}

/// One circle around an aircraft marker: the ping of a live flight, dashed
/// while the flight has no signal.
@immutable
class AircraftRing {
  const AircraftRing({
    required this.radius,
    required this.opacity,
    required this.width,
  });

  final double radius;
  final double opacity;
  final double width;

  @override
  bool operator ==(Object other) =>
      other is AircraftRing &&
      other.radius == radius &&
      other.opacity == opacity &&
      other.width == width;

  @override
  int get hashCode => Object.hash(radius, opacity, width);
}

class AircraftMarkerPainter extends CustomPainter {
  const AircraftMarkerPainter({
    required this.colors,
    required this.state,
    required this.trackDegrees,
    required this.silhouetteScale,
    this.rings = const [],
    this.contourWidth = 1.4,
  });

  static const _viewBoxSize = 48.0;
  static const _ringDash = 4.0;

  final MapColors colors;
  final FlightState state;
  final double trackDegrees;
  final double silhouetteScale;
  final List<AircraftRing> rings;
  final double contourWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final isNoSignal = state == FlightState.noSignal;
    for (final ring in rings) {
      _paintRing(canvas, center, ring, isNoSignal: isNoSignal);
    }
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(trackDegrees * pi / 180)
      ..scale(silhouetteScale)
      ..translate(-_viewBoxSize / 2, -_viewBoxSize / 2)
      ..drawPath(
        aircraftSilhouette,
        Paint()..color = isNoSignal ? colors.noSignalFill : colors.aircraftFill,
      )
      ..drawPath(
        aircraftSilhouette,
        Paint()
          ..color = isNoSignal ? colors.noSignalContour : colors.aircraftContour
          ..style = PaintingStyle.stroke
          ..strokeWidth = contourWidth,
      )
      ..restore();
  }

  void _paintRing(
    Canvas canvas,
    Offset center,
    AircraftRing ring, {
    required bool isNoSignal,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring.width
      ..color = (isNoSignal ? colors.noSignalContour : colors.aircraftFill)
          .withValues(alpha: ring.opacity);
    if (!isNoSignal) {
      canvas.drawCircle(center, ring.radius, paint);
      return;
    }
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: ring.radius));
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _ringDash * 2) {
        canvas.drawPath(
          metric.extractPath(start, min(start + _ringDash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AircraftMarkerPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.state != state ||
      oldDelegate.trackDegrees != trackDegrees ||
      oldDelegate.silhouetteScale != silhouetteScale ||
      oldDelegate.contourWidth != contourWidth ||
      !listEquals(oldDelegate.rings, rings);
}

final aircraftSilhouette = Path()
  ..moveTo(24, 7)
  ..cubicTo(25.6, 7, 26.4, 9.5, 26.4, 12)
  ..lineTo(26.4, 18.5)
  ..lineTo(40, 26)
  ..lineTo(40, 29.5)
  ..lineTo(26.4, 25.5)
  ..lineTo(26.4, 32.5)
  ..lineTo(30.5, 36.5)
  ..lineTo(30.5, 39.5)
  ..lineTo(24, 37.5)
  ..lineTo(17.5, 39.5)
  ..lineTo(17.5, 36.5)
  ..lineTo(21.6, 32.5)
  ..lineTo(21.6, 25.5)
  ..lineTo(8, 29.5)
  ..lineTo(8, 26)
  ..lineTo(21.6, 18.5)
  ..lineTo(21.6, 12)
  ..cubicTo(21.6, 9.5, 22.4, 7, 24, 7)
  ..close();
