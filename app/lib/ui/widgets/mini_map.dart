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
import 'map_visuals.dart';

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

  static const _fitPadding = EdgeInsets.all(28);
  static const _markerSize = 40.0;
  static const _silhouetteScale = 0.5;
  static const _ringRadius = 14.0;
  static const _ringWidth = 1.4;
  static const _airportDotRadius = 4.0;
  static const _trailWidth = 2.2;
  static const _plannedLegWidth = 1.8;
  static const _plannedLegDash = [6.0, 5.0];

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
    final points = _focusPoints(widget);
    if (listEquals(points, _focusPoints(oldWidget))) {
      return;
    }
    final fit = cameraFitFor(points, padding: MiniMap._fitPadding);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (fit == null) {
        _mapController.move(points.last, flightRegionalZoom);
      } else {
        _mapController.fitCamera(fit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = MapColors.of(context);
    final points = _focusPoints(widget);
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
              initialCameraFit: cameraFitFor(
                points,
                padding: MiniMap._fitPadding,
              ),
              initialCenter: aircraft,
              initialZoom: flightRegionalZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
              backgroundColor: colors.mapBackground,
              keepAlive: true,
            ),
            children: [
              mapTiles(colors: colors, tileProvider: widget.tileProvider),
              PolylineLayer(
                polylines: flightPolylines(
                  colors: colors,
                  state: widget.state,
                  route: route,
                  trail: widget.trail,
                  aircraft: aircraft,
                  trailWidth: MiniMap._trailWidth,
                  plannedLegWidth: MiniMap._plannedLegWidth,
                  plannedLegDash: MiniMap._plannedLegDash,
                ),
              ),
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

  List<LatLng> _focusPoints(MiniMap map) => flightFocusPoints(
    position: map.position,
    route: map.route,
    trail: map.trail,
  );

  List<Marker> _markers(
    MapColors colors,
    FlightRoute? route,
    LatLng aircraft,
  ) => [
    if (route != null) ...[
      _airportMarker(colors, route.origin),
      _airportMarker(colors, route.destination),
    ],
    Marker(
      point: aircraft,
      width: MiniMap._markerSize,
      height: MiniMap._markerSize,
      child: CustomPaint(
        painter: AircraftMarkerPainter(
          colors: colors,
          state: widget.state,
          trackDegrees: widget.position.trackDegrees ?? 0,
          silhouetteScale: MiniMap._silhouetteScale,
          rings: [
            AircraftRing(
              radius: MiniMap._ringRadius,
              opacity: widget.state == FlightState.noSignal
                  ? 1
                  : colors.pingOpacity,
              width: MiniMap._ringWidth,
            ),
          ],
        ),
      ),
    ),
  ];

  Marker _airportMarker(MapColors colors, RouteAirport airport) =>
      airportMarker(
        colors: colors,
        airport: airport,
        dotRadius: MiniMap._airportDotRadius,
        labelStyle: AppTextStyles.captionEmphasis,
      );
}
