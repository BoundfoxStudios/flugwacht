import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/map_style.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/l10n/app_localizations_en.g.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/theme/reduced_map_theme.dart';
import 'package:flugwacht/ui/widgets/map/map_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../support/test_dependencies.dart';

const _route = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDF',
    iataCode: 'FRA',
    name: 'Frankfurt am Main',
    latitude: 50.026402,
    longitude: 8.543130,
  ),
  destination: RouteAirport(
    icaoCode: 'KJFK',
    iataCode: 'JFK',
    name: 'New York JFK',
    latitude: 40.639447,
    longitude: -73.779317,
  ),
);

final _position = FixPosition(
  latitude: 48.5,
  longitude: -20,
  timestamp: DateTime.utc(2026, 8, 12, 12),
  trackDegrees: 271.4,
);

void main() {
  test('keeps route, trail and position in view', () {
    final trail = [
      TrailPoint(
        timestamp: DateTime.utc(2026, 8, 12, 11),
        latitude: 49,
        longitude: 2,
        sourceId: SourceId.adsblol,
      ),
    ];

    expect(
      flightFocusPoints(position: _position, route: _route, trail: trail),
      [
        const LatLng(50.026402, 8.543130),
        const LatLng(40.639447, -73.779317),
        const LatLng(49, 2),
        const LatLng(48.5, -20),
      ],
    );
  });

  test('falls back to the position alone without a route', () {
    expect(
      flightFocusPoints(position: _position, route: null, trail: const []),
      [const LatLng(48.5, -20)],
    );
  });

  test('has no camera fit for a single point', () {
    expect(
      cameraFitFor(const [LatLng(50, 10)], padding: EdgeInsets.zero),
      isNull,
    );
  });

  test('has no camera fit for points on one spot of the globe', () {
    expect(
      cameraFitFor(const [
        LatLng(50, 10),
        LatLng(50.001, 10.001),
      ], padding: EdgeInsets.zero),
      isNull,
    );
  });

  group('trail rendering', () {
    TrailPoint pointAt(double latitude, {required SourceId sourceId}) =>
        TrailPoint(
          timestamp: DateTime.utc(2026, 8, 12, 11),
          latitude: latitude,
          longitude: 2,
          sourceId: sourceId,
        );

    List<Polyline<Object>> trailPolylines(List<TrailPoint> trail) =>
        flightPolylines(
          colors: MapColors.light,
          state: FlightState.live,
          route: null,
          trail: trail,
          aircraft: const LatLng(48.5, -20),
          trailWidth: 2.5,
          plannedLegWidth: 2,
          plannedLegDash: const [7, 6],
        );

    test('draws one line up to the aircraft while one source delivers', () {
      final polylines = trailPolylines([
        pointAt(49, sourceId: SourceId.adsblol),
        pointAt(48.8, sourceId: SourceId.adsblol),
      ]);

      expect(polylines.single.points, const [
        LatLng(49, 2),
        LatLng(48.8, 2),
        LatLng(48.5, -20),
      ]);
      expect(polylines.single.color, MapColors.light.trail);
    });

    test('splits the trail into one segment per source run', () {
      final polylines = trailPolylines([
        pointAt(49, sourceId: SourceId.adsblol),
        pointAt(48.9, sourceId: SourceId.adsbfi),
        pointAt(48.8, sourceId: SourceId.adsbfi),
        pointAt(48.7, sourceId: SourceId.adsblol),
      ]);

      expect(polylines.map((polyline) => polyline.color), [
        AppColors.amber,
        AppColors.orange,
        AppColors.amber,
      ]);
      expect(polylines[1].points, const [
        LatLng(49, 2),
        LatLng(48.9, 2),
        LatLng(48.8, 2),
      ]);
    });

    test('extends the last segment to the aircraft', () {
      final polylines = trailPolylines([
        pointAt(49, sourceId: SourceId.adsblol),
        pointAt(48.8, sourceId: SourceId.adsbfi),
      ]);

      expect(polylines.last.points.last, const LatLng(48.5, -20));
    });

    test('colors airplanes.live for the theme it draws on', () {
      expect(MapColors.light.trailOf(SourceId.airplanes), AppColors.neutral500);
      expect(MapColors.dark.trailOf(SourceId.airplanes), AppColors.neutral300);
    });
  });

  test('fits the bounds of points that span a distance', () {
    final fit = cameraFitFor(const [
      LatLng(50, 10),
      LatLng(40, -73),
    ], padding: const EdgeInsets.all(40));

    expect(
      fit,
      isA<FitBounds>()
          .having((fit) => fit.bounds.north, 'north', 50)
          .having((fit) => fit.bounds.south, 'south', 40)
          .having((fit) => fit.bounds.east, 'east', 10)
          .having((fit) => fit.bounds.west, 'west', -73)
          .having((fit) => fit.padding, 'padding', const EdgeInsets.all(40)),
    );
  });

  /// The raster style's own layer; the vector layer builds a `TileLayer` of
  /// its own that this finder leaves alone.
  final osmTiles = find.byWidgetPredicate(
    (widget) => widget is TileLayer && widget.urlTemplate != null,
  );

  Future<void> pumpTiles(
    WidgetTester tester, {
    required MapStyle style,
    Brightness brightness = Brightness.light,
    bool withVectorTiles = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          options: const MapOptions(),
          children: [
            mapTiles(
              colors: switch (brightness) {
                Brightness.light => MapColors.light,
                Brightness.dark => MapColors.dark,
              },
              style: style,
              sources: testTileSources(withVectorTiles: withVectorTiles),
            ),
          ],
        ),
      ),
    );
    // The vector layer schedules its cache housekeeping three seconds out.
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('draws the reduced style from vector tiles', (tester) async {
    await pumpTiles(tester, style: MapStyle.reduced);

    expect(find.byType(VectorTileLayer), findsOneWidget);
    expect(osmTiles, findsNothing);
  });

  testWidgets('draws the OSM style from raster tiles', (tester) async {
    await pumpTiles(tester, style: MapStyle.rasterOsm);

    expect(osmTiles, findsOneWidget);
    expect(find.byType(VectorTileLayer), findsNothing);
  });

  testWidgets('draws no tiles while the reduced style has no endpoint', (
    tester,
  ) async {
    await pumpTiles(tester, style: MapStyle.reduced, withVectorTiles: false);

    expect(find.byType(VectorTileLayer), findsNothing);
  });

  testWidgets('renders the reduced style in a theme variant of its own', (
    tester,
  ) async {
    await pumpTiles(
      tester,
      style: MapStyle.reduced,
      brightness: Brightness.dark,
    );

    expect(
      tester.widget<VectorTileLayer>(find.byType(VectorTileLayer)).theme,
      same(reducedMapTheme(Brightness.dark)),
    );
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('inverts the raster tiles for the dark theme', (tester) async {
    await pumpTiles(
      tester,
      style: MapStyle.rasterOsm,
      brightness: Brightness.dark,
    );

    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  test('credits OpenMapTiles for the reduced style', () {
    expect(
      mapTileAttribution(AppLocalizationsEn(), MapStyle.reduced),
      '© OpenStreetMap · © OpenMapTiles',
    );
  });

  test('credits OpenStreetMap alone for the raster style', () {
    expect(
      mapTileAttribution(AppLocalizationsEn(), MapStyle.rasterOsm),
      '© OpenStreetMap',
    );
  });

  testWidgets('identifies the tile requests with the installed package', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'Flugwacht',
      packageName: 'com.boundfoxstudios.apps.flugwacht',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final packageInfo = await PackageInfo.fromPlatform();

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          options: const MapOptions(),
          children: [
            mapTiles(
              colors: MapColors.light,
              style: MapStyle.rasterOsm,
              sources: testTileSources(
                userAgentPackageName: packageInfo.packageName,
              ),
            ),
          ],
        ),
      ),
    );

    expect(
      tester
          .widget<TileLayer>(find.byType(TileLayer))
          .tileProvider
          .headers['User-Agent'],
      'flutter_map (com.boundfoxstudios.apps.flugwacht)',
    );
  });
}
