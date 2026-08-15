import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../domain/fix.dart';
import '../../domain/flight_route.dart';
import '../../domain/flight_state.dart';
import '../../domain/trail_point.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

/// The points the mini map has to keep in view: the route ends, the flown
/// trail and the latest position.
List<LatLng> miniMapFocusPoints({
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

/// The non-interactive map of the list hero: flown trail, planned leg, the
/// route's airports and the aircraft at its latest position.
class MiniMap extends StatefulWidget {
  const MiniMap({
    required this.position,
    required this.route,
    required this.trail,
    required this.state,
    super.key,
    this.tileProvider,
  });

  /// Zoom for a flight whose points are one spot on the globe — a flight
  /// without a route, or one whose trail has not moved away from it yet.
  static const _regionalZoom = 6.0;
  static const _fitPadding = EdgeInsets.all(28);

  /// Degrees the points have to span before fitting them beats the fixed zoom.
  static const _minimumFitSpan = 0.01;

  final FixPosition position;
  final FlightRoute? route;
  final List<TrailPoint> trail;
  final FlightState state;

  /// Injectable so tests render without loading tiles over the network.
  final TileProvider? tileProvider;

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MiniMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final points = miniMapFocusPoints(
      position: widget.position,
      route: widget.route,
      trail: widget.trail,
    );
    final previous = miniMapFocusPoints(
      position: oldWidget.position,
      route: oldWidget.route,
      trail: oldWidget.trail,
    );
    if (listEquals(points, previous)) {
      return;
    }
    final fit = _cameraFit(points);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (fit == null) {
        _mapController.move(points.last, MiniMap._regionalZoom);
      } else {
        _mapController.fitCamera(fit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _MapColors.light,
      Brightness.dark => _MapColors.dark,
    };
    final points = miniMapFocusPoints(
      position: widget.position,
      route: widget.route,
      trail: widget.trail,
    );
    final aircraft = LatLng(
      widget.position.latitude,
      widget.position.longitude,
    );
    final route = widget.route;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: _cameraFit(points),
              initialCenter: aircraft,
              initialZoom: MiniMap._regionalZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
              backgroundColor: colors.mapBackground,
              keepAlive: true,
            ),
            children: [
              _tiles(colors),
              PolylineLayer(polylines: _polylines(colors, route, aircraft)),
              MarkerLayer(markers: _markers(colors, route, aircraft)),
            ],
          ),
        ),
        Positioned(
          right: AppSpacing.grid,
          bottom: AppSpacing.grid / 2,
          child: Text(
            AppLocalizations.of(context).mapAttributionOpenStreetMap,
            style: AppTextStyles.attribution.copyWith(
              color: AppColors.neutral400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tiles(_MapColors colors) {
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'de.boundfoxstudios.flugwacht',
      // A fresh instance per build is what TileLayer does by default; it takes
      // ownership and disposes whatever it is handed.
      tileProvider: widget.tileProvider ?? NetworkTileProvider(),
    );
    return colors.tileFilter == null
        ? tiles
        : ColorFiltered(colorFilter: colors.tileFilter!, child: tiles);
  }

  List<Polyline<Object>> _polylines(
    _MapColors colors,
    FlightRoute? route,
    LatLng aircraft,
  ) => [
    if (widget.trail.isNotEmpty)
      Polyline(
        points: [
          for (final point in widget.trail)
            LatLng(point.latitude, point.longitude),
          aircraft,
        ],
        color: colors.trail,
        strokeWidth: 2.2,
      ),
    if (route != null)
      Polyline(
        points: [
          aircraft,
          LatLng(route.destination.latitude, route.destination.longitude),
        ],
        color: widget.state == FlightState.noSignal
            ? colors.plannedLegNoSignal
            : colors.plannedLeg,
        strokeWidth: 1.8,
        pattern: StrokePattern.dashed(segments: const [6, 5]),
      ),
  ];

  List<Marker> _markers(
    _MapColors colors,
    FlightRoute? route,
    LatLng aircraft,
  ) => [
    if (route != null) ...[
      _airportMarker(colors, route.origin),
      _airportMarker(colors, route.destination),
    ],
    Marker(
      point: aircraft,
      width: _AircraftPainter.markerSize,
      height: _AircraftPainter.markerSize,
      child: CustomPaint(
        painter: _AircraftPainter(
          colors: colors,
          state: widget.state,
          trackDegrees: widget.position.trackDegrees ?? 0,
        ),
      ),
    ),
  ];

  Marker _airportMarker(_MapColors colors, RouteAirport airport) => Marker(
    point: LatLng(airport.latitude, airport.longitude),
    width: _airportMarkerWidth,
    height: _airportMarkerHeight,
    child: Stack(
      children: [
        Positioned(
          left: _airportMarkerWidth / 2 - _airportDotRadius,
          top: _airportMarkerHeight / 2 - _airportDotRadius,
          width: _airportDotRadius * 2,
          height: _airportDotRadius * 2,
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
              style: AppTextStyles.captionEmphasis.copyWith(
                color: colors.airportLabel,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// Null whenever the points are one spot on the globe: fitting a bounds
  /// without an area blows the zoom up to infinity.
  CameraFit? _cameraFit(List<LatLng> points) {
    if (points.length < 2) {
      return null;
    }
    final bounds = LatLngBounds.fromPoints(points);
    final span = max(bounds.north - bounds.south, bounds.east - bounds.west);
    return span < MiniMap._minimumFitSpan
        ? null
        : CameraFit.bounds(bounds: bounds, padding: MiniMap._fitPadding);
  }
}

const _airportMarkerWidth = 96.0;
const _airportMarkerHeight = 24.0;
const _airportDotRadius = 4.0;
const _airportLabelOffset = 8.0;

/// Inverts and hue-rotates the raster tiles so the light OSM style carries the
/// dark theme until the reduced style of M11 replaces it.
const _darkTileFilter = ColorFilter.matrix(<double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

enum _MapColors {
  light(
    mapBackground: AppColors.white,
    trail: AppColors.neutral700,
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

  const _MapColors({
    required this.mapBackground,
    required this.trail,
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

  final Color mapBackground;
  final Color trail;
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

class _AircraftPainter extends CustomPainter {
  const _AircraftPainter({
    required this.colors,
    required this.state,
    required this.trackDegrees,
  });

  static const markerSize = 40.0;
  static const _viewBoxSize = 48.0;
  static const _silhouetteScale = 0.5;
  static const _contourWidth = 1.4;
  static const _ringRadius = 14.0;
  static const _ringWidth = 1.4;
  static const _ringDash = 4.0;

  final _MapColors colors;
  final FlightState state;
  final double trackDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final isNoSignal = state == FlightState.noSignal;
    _paintRing(canvas, center, isNoSignal: isNoSignal);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(trackDegrees * pi / 180)
      ..scale(_silhouetteScale)
      ..translate(-_viewBoxSize / 2, -_viewBoxSize / 2)
      ..drawPath(
        _silhouette,
        Paint()..color = isNoSignal ? colors.noSignalFill : colors.aircraftFill,
      )
      ..drawPath(
        _silhouette,
        Paint()
          ..color = isNoSignal ? colors.noSignalContour : colors.aircraftContour
          ..style = PaintingStyle.stroke
          ..strokeWidth = _contourWidth,
      )
      ..restore();
  }

  void _paintRing(Canvas canvas, Offset center, {required bool isNoSignal}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth
      ..color = isNoSignal
          ? colors.noSignalContour
          : colors.aircraftFill.withValues(alpha: colors.pingOpacity);
    if (!isNoSignal) {
      canvas.drawCircle(center, _ringRadius, paint);
      return;
    }
    final ring = Path()
      ..addOval(Rect.fromCircle(center: center, radius: _ringRadius));
    for (final metric in ring.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _ringDash * 2) {
        canvas.drawPath(
          metric.extractPath(start, min(start + _ringDash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AircraftPainter oldDelegate) =>
      oldDelegate.colors != colors ||
      oldDelegate.state != state ||
      oldDelegate.trackDegrees != trackDegrees;
}

final _silhouette = Path()
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
