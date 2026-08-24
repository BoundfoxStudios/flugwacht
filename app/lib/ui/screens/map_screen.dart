import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../app_icons.dart';
import '../../data/live_activities/live_activity_service.dart';
import '../../data/persistence/flight_repository.dart';
import '../../data/settings/map_style_setting.dart';
import '../../data/settings/source_setting.dart';
import '../../data/settings/units_setting.dart';
import '../../domain/flight_state.dart';
import '../../domain/map_style.dart';
import '../../domain/source_id.dart';
import '../../l10n/app_localizations.g.dart';
import '../map_selection.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/flight/flight_sheet.dart';
import '../widgets/map/map_button.dart';
import '../widgets/map/map_visuals.dart';
import '../widgets/map/source_legend_card.dart';
import 'list_sections.dart';
import 'map_flights.dart';

/// The peek height the map is framed around; the camera keeps that
/// much room free so the sheet never covers the framed flight.
const mapSheetPeekHeight = 176.0;

/// The full-screen map: every flight with a position as a marker, the selected
/// flight with its trail, planned leg and airports, framed by an animated
/// camera.
class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.flightRepository,
    required this.selection,
    required this.sourceSetting,
    required this.unitsSetting,
    required this.mapStyleSetting,
    required this.liveActivityService,
    required this.tileSources,
    super.key,
    this.clock = DateTime.now,
  });

  static const _defaultCenter = LatLng(50, 10);
  static const _defaultZoom = 4.0;
  static const _fitPadding = EdgeInsets.fromLTRB(
    40,
    40,
    40,
    40 + mapSheetPeekHeight,
  );
  static const _cameraDuration = Duration(milliseconds: 200);
  static const _pingDuration = Duration(milliseconds: 2500);
  static const _pingRings = [
    (radius: 20.0, opacity: 0.5),
    (radius: 30.0, opacity: 0.22),
  ];
  static const _pingStartScale = 0.6;
  static const _noSignalRingRadius = 18.0;
  static const _ringWidth = 1.5;
  static const _markerSize = 68.0;
  static const _silhouetteScale = 0.62;
  static const _airportDotRadius = 5.0;
  static const _trailWidth = 2.5;
  static const _comparedTrailWidth = 3.0;
  static const _plannedLegWidth = 2.0;
  static const _plannedLegDash = [7.0, 6.0];
  static const _buttonTopInset = 7.0;
  static const _buttonRightInset = 14.0;

  final FlightRepository flightRepository;
  final MapSelection selection;
  final SourceSetting sourceSetting;
  final UnitsSetting unitsSetting;
  final MapStyleSetting mapStyleSetting;
  final LiveActivityService liveActivityService;

  /// Reads the current time; injectable so the minute ticker stays testable.
  final DateTime Function() clock;

  final MapTileSources tileSources;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final _mapFlights = MapFlights(
    repository: widget.flightRepository,
    selection: widget.selection,
    clock: widget.clock,
  );
  final _mapController = MapController();
  late final _cameraController = AnimationController(
    vsync: this,
    duration: MapScreen._cameraDuration,
  )..addListener(_moveCamera);
  late final _pingController = AnimationController(
    vsync: this,
    duration: MapScreen._pingDuration,
  );
  late final EffectCleanup _stopFramingSelection;
  late final EffectCleanup _stopPinging;
  var _isSheetOpen = false;
  LatLng? _cameraStartCenter;
  LatLng? _cameraTargetCenter;
  double _cameraStartZoom = MapScreen._defaultZoom;
  double _cameraTargetZoom = MapScreen._defaultZoom;

  @override
  void initState() {
    super.initState();
    _stopFramingSelection = effect(() {
      if (_mapFlights.selectedId.value == null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _frameSelection());
    });
    _stopPinging = effect(() {
      if (_mapFlights.selected.value?.state == FlightState.live) {
        if (!_pingController.isAnimating) {
          unawaited(_pingController.repeat());
        }
      } else {
        _pingController.stop();
      }
    });
  }

  @override
  void dispose() {
    _stopFramingSelection();
    _stopPinging();
    _cameraController.dispose();
    _pingController.dispose();
    _mapController.dispose();
    _mapFlights.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = MapColors.of(context);
    return Scaffold(
      body: SignalBuilder(
        builder: (context) {
          final entries = _mapFlights.flights.value;
          final selected = _mapFlights.selected.value;
          final trail = _mapFlights.trail.value;
          final route = selected?.flight.route;
          final position = selected?.flight.tracking.latestPosition;
          final showsSourceComparison = comparesSources(trail);
          final mapStyle = widget.mapStyleSetting.style.value;
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: MapScreen._defaultCenter,
                  initialZoom: MapScreen._defaultZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  backgroundColor: colors.mapBackground,
                ),
                children: [
                  mapTiles(
                    colors: colors,
                    style: mapStyle,
                    sources: widget.tileSources,
                  ),
                  if (selected != null && position != null) ...[
                    PolylineLayer(
                      polylines: flightPolylines(
                        colors: colors,
                        state: selected.state,
                        route: route,
                        trail: trail,
                        aircraft: LatLng(position.latitude, position.longitude),
                        trailWidth: showsSourceComparison
                            ? MapScreen._comparedTrailWidth
                            : MapScreen._trailWidth,
                        plannedLegWidth: MapScreen._plannedLegWidth,
                        plannedLegDash: MapScreen._plannedLegDash,
                      ),
                    ),
                    if (route != null)
                      MarkerLayer(
                        markers: [
                          for (final airport in [
                            route.origin,
                            route.destination,
                          ])
                            airportMarker(
                              colors: colors,
                              airport: airport,
                              dotRadius: MapScreen._airportDotRadius,
                              labelStyle: AppTextStyles.smallEmphasis,
                            ),
                        ],
                      ),
                  ],
                  AnimatedBuilder(
                    animation: _pingController,
                    builder: (context, _) => MarkerLayer(
                      markers: _aircraftMarkers(
                        colors,
                        entries,
                        selected?.flight.id,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: MapScreen._buttonTopInset,
                right: MapScreen._buttonRightInset,
                child: SafeArea(
                  child: Column(
                    spacing: MapButton.gap,
                    children: [
                      MapButton(
                        icon: AppIcons.layerGroup,
                        semanticsLabel: AppLocalizations.of(
                          context,
                        ).mapStyleToggleLabel,
                        onPressed: () =>
                            unawaited(widget.mapStyleSetting.toggle()),
                      ),
                      MapButton(
                        icon: AppIcons.locationArrow,
                        semanticsLabel: AppLocalizations.of(
                          context,
                        ).mapRecenterLabel,
                        onPressed: _frameSelection,
                      ),
                    ],
                  ),
                ),
              ),
              if (showsSourceComparison && !_isSheetOpen)
                Positioned(
                  left: AppSpacing.cardPadding,
                  top: AppSpacing.cardPadding,
                  child: SafeArea(
                    child: SignalBuilder(
                      builder: (context) => SourceLegendCard(
                        trailSourceIds: trailSourceIds(trail),
                        activeId: widget.sourceSetting.activeId.value,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isSheetOpen)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.cardPadding,
                            bottom: AppSpacing.grid,
                          ),
                          child: _AttributionChip(
                            sourceSetting: widget.sourceSetting,
                            mapStyle: mapStyle,
                          ),
                        ),
                      ),
                    if (selected != null)
                      FlightSheet(
                        entries: entries,
                        selectedIndex: entries.indexOf(selected),
                        onSelected: (index) => _mapFlights.selectedId.value =
                            entries[index].flight.id,
                        sourceSetting: widget.sourceSetting,
                        unitsSetting: widget.unitsSetting,
                        mapStyle: mapStyle,
                        liveActivityService: widget.liveActivityService,
                        onLiveActivityArmed: (flight, {required isArmed}) =>
                            unawaited(
                              widget.flightRepository.setLiveActivityArmed(
                                flight.id,
                                isArmed: isArmed,
                              ),
                            ),
                        onOpenChanged: (isOpen) =>
                            setState(() => _isSheetOpen = isOpen),
                        clock: widget.clock,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _aircraftMarkers(
    MapColors colors,
    List<FlightListEntry> entries,
    int? selectedId,
  ) => [
    for (final entry in entries)
      if (entry.flight.tracking.latestPosition case final position?)
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: MapScreen._markerSize,
          height: MapScreen._markerSize,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _mapFlights.selectedId.value = entry.flight.id,
            child: CustomPaint(
              painter: AircraftMarkerPainter(
                colors: colors,
                state: entry.state,
                trackDegrees: position.trackDegrees ?? 0,
                silhouetteScale: MapScreen._silhouetteScale,
                rings: entry.flight.id == selectedId
                    ? _selectionRings(entry.state)
                    : const [],
              ),
            ),
          ),
        ),
  ];

  List<AircraftRing> _selectionRings(FlightState state) {
    if (state == FlightState.noSignal) {
      return const [
        AircraftRing(
          radius: MapScreen._noSignalRingRadius,
          opacity: 1,
          width: MapScreen._ringWidth,
        ),
      ];
    }
    final progress = Curves.easeOut.transform(_pingController.value);
    final scale =
        MapScreen._pingStartScale + (1 - MapScreen._pingStartScale) * progress;
    return [
      for (final ring in MapScreen._pingRings)
        AircraftRing(
          radius: ring.radius * scale,
          opacity: ring.opacity * (1 - progress),
          width: MapScreen._ringWidth,
        ),
    ];
  }

  void _frameSelection() {
    if (!mounted) {
      return;
    }
    final selected = _mapFlights.selected.peek();
    final position = selected?.flight.tracking.latestPosition;
    if (selected == null || position == null) {
      return;
    }
    final points = flightFocusPoints(
      position: position,
      route: selected.flight.route,
      trail: _mapFlights.trail.peek(),
    );
    final camera = _mapController.camera;
    final fit = cameraFitFor(points, padding: MapScreen._fitPadding);
    final target = fit?.fit(camera);
    _cameraStartCenter = camera.center;
    _cameraStartZoom = camera.zoom;
    _cameraTargetCenter = target?.center ?? points.last;
    _cameraTargetZoom = target?.zoom ?? flightRegionalZoom;
    _cameraController
      ..reset()
      ..forward();
  }

  void _moveCamera() {
    final start = _cameraStartCenter;
    final target = _cameraTargetCenter;
    if (start == null || target == null) {
      return;
    }
    final progress = Curves.easeInOut.transform(_cameraController.value);
    _mapController.move(
      LatLng(
        lerpDouble(start.latitude, target.latitude, progress)!,
        lerpDouble(start.longitude, target.longitude, progress)!,
      ),
      lerpDouble(_cameraStartZoom, _cameraTargetZoom, progress)!,
    );
  }
}

class _AttributionChip extends StatelessWidget {
  const _AttributionChip({required this.sourceSetting, required this.mapStyle});

  static const _padding = EdgeInsets.symmetric(horizontal: 7, vertical: 2);
  static const _radius = 4.0;
  static const _lightBackground = Color(0xd9ffffff);
  static const _darkBackground = Color(0xd9262626);

  final SourceSetting sourceSetting;
  final MapStyle mapStyle;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: switch (Theme.of(context).brightness) {
        Brightness.light => _lightBackground,
        Brightness.dark => _darkBackground,
      },
      borderRadius: BorderRadius.circular(_radius),
    ),
    child: Padding(
      padding: _padding,
      child: SignalBuilder(
        builder: (context) {
          final localizations = AppLocalizations.of(context);
          return Text(
            localizations.mapAttributionWithSource(
              mapTileAttribution(localizations, mapStyle),
              sourceSetting.activeId.value.label,
            ),
            style: AppTextStyles.attribution.copyWith(
              color: AppColors.neutral400,
            ),
          );
        },
      ),
    ),
  );
}
