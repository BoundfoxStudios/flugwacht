import 'package:flugwacht/app_icons.dart';
import 'package:flugwacht/data/map_style_setting.dart';
import 'package:flugwacht/data/source_setting.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/main.dart';
import 'package:flugwacht/ui/app_router.dart';
import 'package:flugwacht/ui/map_selection.dart';
import 'package:flugwacht/ui/screens/map_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/flight_hero_cell.dart';
import 'package:flugwacht/ui/widgets/flight_sheet.dart';
import 'package:flugwacht/ui/widgets/map_button.dart';
import 'package:flugwacht/ui/widgets/map_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../support/test_dependencies.dart';

const _departureDate = CalendarDate(2026, 8, 12);
final _window = FlightDayWindow.forDepartureDate(_departureDate);
final _now = _window.start.add(const Duration(hours: 4));

const _frankfurtToNewYork = FlightRoute(
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

const _munichToLisbon = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDM',
    iataCode: 'MUC',
    name: 'München',
    latitude: 48.353802,
    longitude: 11.786100,
  ),
  destination: RouteAirport(
    icaoCode: 'LPPT',
    iataCode: 'LIS',
    name: 'Lisboa',
    latitude: 38.781311,
    longitude: -9.135919,
  ),
);

Flight _airborneFlight(
  int id, {
  FlightRoute? route,
  Duration positionAge = Duration.zero,
  double latitude = 48.5,
  double longitude = -20,
}) => Flight(
  id: id,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH40$id',
  departureDate: _departureDate,
  route: route,
  tracking: FlightTracking(
    latestPosition: FixPosition(
      latitude: latitude,
      longitude: longitude,
      timestamp: _now.subtract(positionAge),
    ),
    hasBeenAirborne: true,
  ),
);

const _waitingFlight = Flight(
  id: 9,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH999',
  departureDate: _departureDate,
);

Future<FakeFlightRepository> pumpMapScreen(
  WidgetTester tester, {
  List<Flight> flights = const [],
  List<TrailPoint> trail = const [],
  MapSelection? selection,
  SourceSetting? sourceSetting,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  bool withVectorTiles = false,
  MapStyleSetting? mapStyleSetting,
}) async {
  final repository = FakeFlightRepository();
  addTearDown(repository.dispose);
  final mapSelection = selection ?? MapSelection();
  addTearDown(mapSelection.dispose);
  final setting = sourceSetting ?? await createTestSourceSetting();
  final styleSetting = mapStyleSetting ?? await createTestMapStyleSetting();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: MapScreen(
        flightRepository: repository,
        selection: mapSelection,
        sourceSetting: setting,
        unitsSetting: await createTestUnitsSetting(),
        clock: () => _now,
        mapStyleSetting: styleSetting,
        tileSources: testTileSources(withVectorTiles: withVectorTiles),
      ),
    ),
  );
  repository.emit(flights);
  await tester.pump();
  if (trail.isNotEmpty) {
    repository.emitTrail(trail);
    await tester.pump();
  }
  // Lets the camera settle on the selected flight; markers outside the
  // viewport are not built.
  await tester.pump(const Duration(milliseconds: 300));
  if (withVectorTiles) {
    // The vector layer schedules its cache housekeeping three seconds out.
    await tester.pump(const Duration(seconds: 3));
  }
  return repository;
}

/// Two flights airborne right now, so the app's own clock keeps them on the
/// map.
List<Flight> flightsAirborneNow() {
  final today = DateTime.now();
  return [
    for (final (id, latitude) in [(1, 48.5), (2, 51.5)])
      Flight(
        id: id,
        lookupKind: FlightLookupKind.flightNumber,
        lookupValue: 'LH40$id',
        departureDate: CalendarDate(today.year, today.month, today.day),
        tracking: FlightTracking(
          latestPosition: FixPosition(
            latitude: latitude,
            longitude: -20,
            timestamp: today.toUtc(),
          ),
          hasBeenAirborne: true,
        ),
      ),
  ];
}

Future<FakeFlightRepository> pumpApp(WidgetTester tester) async {
  final repository = FakeFlightRepository();
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    FlugwachtApp(
      router: createAppRouter(
        flightRepository: repository,
        airlineDirectory: createTestAirlineDirectory(),
        routeLookup: FakeRouteLookup(),
        sourceSetting: await createTestSourceSetting(),
        mapStyleSetting: await createTestMapStyleSetting(),
        unitsSetting: await createTestUnitsSetting(),
        tileSources: testTileSources(),
        packageInfo: testPackageInfo(),
      ),
    ),
  );
  repository.emit(flightsAirborneNow());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return repository;
}

/// Runs the camera animation to its end: one frame starts its ticker, the
/// next carries it past the animation, the last one lets the map rebuild on
/// the camera it landed on.
Future<void> settleCamera(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Finder mapButtonWith(FaIconData icon) => find.byWidgetPredicate(
  (widget) => widget is MapButton && widget.icon == icon,
);

/// The camera the map settled on, read through a layer inside the map.
MapCamera cameraOf(WidgetTester tester) =>
    MapCamera.of(tester.element(find.byType(MarkerLayer).first));

Finder aircraftMarkerAt(int index) => find
    .byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is AircraftMarkerPainter,
    )
    .at(index);

Iterable<AircraftMarkerPainter> aircraftMarkers(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<AircraftMarkerPainter>();

List<Polyline<Object>> polylines(WidgetTester tester) {
  final layers = tester.widgetList<PolylineLayer<Object>>(
    find.byType(PolylineLayer<Object>),
  );
  return [for (final layer in layers) ...layer.polylines];
}

void main() {
  testWidgets('marks every flight that has a position', (tester) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1), _waitingFlight, _airborneFlight(2)],
    );

    expect(aircraftMarkers(tester), hasLength(2));
  });

  testWidgets('draws trail and airports of the selected flight alone', (
    tester,
  ) async {
    await pumpMapScreen(
      tester,
      flights: [
        _airborneFlight(1, route: _frankfurtToNewYork),
        _airborneFlight(2, route: _munichToLisbon),
      ],
      trail: [
        TrailPoint(
          timestamp: _now.subtract(const Duration(minutes: 20)),
          latitude: 49,
          longitude: 2,
          sourceId: SourceId.adsblol,
        ),
      ],
    );

    expect(find.text('FRA'), findsOneWidget);
    expect(find.text('JFK'), findsOneWidget);
    expect(find.text('MUC'), findsNothing);
    expect(polylines(tester), hasLength(2));
  });

  testWidgets('rings the selected flight only', (tester) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1), _airborneFlight(2)],
    );

    final markers = aircraftMarkers(tester).toList();
    expect(markers.first.rings, isNotEmpty);
    expect(markers.last.rings, isEmpty);
  });

  testWidgets('rings a selected flight without signal statically', (
    tester,
  ) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1, positionAge: const Duration(hours: 1))],
    );

    final marker = aircraftMarkers(tester).single;
    expect(marker.state, FlightState.noSignal);
    expect(marker.rings, hasLength(1));
    final atRest = marker.rings.single;

    await tester.pump(const Duration(seconds: 1));

    expect(aircraftMarkers(tester).single.rings.single, atRest);
  });

  testWidgets('pings a selected live flight', (tester) async {
    await pumpMapScreen(tester, flights: [_airborneFlight(1)]);
    final atRest = aircraftMarkers(tester).single.rings;

    await tester.pump(const Duration(milliseconds: 800));

    expect(aircraftMarkers(tester).single.rings, isNot(atRest));
  });

  testWidgets('stays a bare map while no flight has a position', (
    tester,
  ) async {
    await pumpMapScreen(tester, flights: [_waitingFlight]);

    expect(aircraftMarkers(tester), isEmpty);
    expect(polylines(tester), isEmpty);
    expect(find.byType(FlightSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheets the selected flight', (tester) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1), _airborneFlight(2)],
    );

    final sheet = tester.widget<FlightSheet>(find.byType(FlightSheet));
    expect(sheet.entries[sheet.selectedIndex].flight.id, 1);
  });

  testWidgets('selects the flight whose marker was tapped', (tester) async {
    final repository = await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1), _airborneFlight(2, latitude: 50)],
    );

    await tester.tap(aircraftMarkerAt(1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<FlightSheet>(find.byType(FlightSheet)).selectedIndex,
      1,
    );
    expect(aircraftMarkers(tester).last.rings, isNotEmpty);
    expect(aircraftMarkers(tester).first.rings, isEmpty);
    expect(repository.watchedTrails, [1, 2]);
  });

  testWidgets('selects the flight the sheet was swiped to', (tester) async {
    final repository = await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1), _airborneFlight(2, latitude: 50)],
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FlightSheet)),
    );
    await tester.pump();
    for (var step = 0; step < 6; step++) {
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(aircraftMarkers(tester).last.rings, isNotEmpty);
    expect(repository.watchedTrails, [1, 2]);
  });

  testWidgets('hands the sheet on when the selected flight leaves the map', (
    tester,
  ) async {
    final repository = await pumpMapScreen(
      tester,
      flights: [
        _airborneFlight(1),
        _airborneFlight(2, latitude: 50),
        _airborneFlight(3, latitude: 51.5),
      ],
    );
    await tester.tap(aircraftMarkerAt(2));
    await tester.pump(const Duration(milliseconds: 400));

    repository.emit([_airborneFlight(1), _airborneFlight(2, latitude: 50)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final sheet = tester.widget<FlightSheet>(find.byType(FlightSheet));
    expect(sheet.entries, hasLength(2));
    expect(sheet.selectedIndex, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps its selection while another tab was in front', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(aircraftMarkerAt(1));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('List'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Map'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<FlightSheet>(find.byType(FlightSheet)).selectedIndex,
      1,
    );
  });

  testWidgets('frames the flight the list handed over', (tester) async {
    final repository = await pumpApp(tester);
    await tester.tap(find.text('List'));
    await tester.pump(const Duration(milliseconds: 300));
    repository.emit(flightsAirborneNow());
    await tester.pump();

    await tester.tap(find.byType(FlightHeroCell).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<FlightSheet>(find.byType(FlightSheet)).selectedIndex,
      1,
    );
  });

  testWidgets('attributes OpenStreetMap and the active source', (tester) async {
    await pumpMapScreen(tester, flights: [_airborneFlight(1)]);

    expect(
      find.text('© OpenStreetMap · © OpenMapTiles · Data: adsb.lol'),
      findsOneWidget,
    );
  });

  testWidgets('attributes in German as well', (tester) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1)],
      locale: const Locale('de'),
    );

    expect(
      find.text('© OpenStreetMap · © OpenMapTiles · Daten: adsb.lol'),
      findsOneWidget,
    );
  });

  group('source comparison', () {
    List<TrailPoint> trailFrom(List<SourceId> sourceIds) => [
      for (final (index, sourceId) in sourceIds.indexed)
        TrailPoint(
          timestamp: _now.subtract(Duration(minutes: 20 - index)),
          latitude: 49 - index * 0.1,
          longitude: 2,
          sourceId: sourceId,
        ),
    ];

    testWidgets('legends the trail once a second source delivered', (
      tester,
    ) async {
      await pumpMapScreen(
        tester,
        flights: [_airborneFlight(1)],
        trail: trailFrom([SourceId.adsblol, SourceId.adsbfi]),
      );

      expect(find.text('TRAIL BY SOURCE'), findsOneWidget);
    });

    testWidgets('leaves a single-source trail as it was', (tester) async {
      await pumpMapScreen(
        tester,
        flights: [_airborneFlight(1)],
        trail: trailFrom([SourceId.adsblol, SourceId.adsblol]),
      );

      expect(find.text('TRAIL BY SOURCE'), findsNothing);
      expect(
        polylines(tester).single,
        isA<Polyline<Object>>()
            .having((line) => line.color, 'color', MapColors.light.trail)
            .having((line) => line.strokeWidth, 'strokeWidth', 2.5),
      );
    });

    testWidgets('thickens the compared trail', (tester) async {
      await pumpMapScreen(
        tester,
        flights: [_airborneFlight(1)],
        trail: trailFrom([SourceId.adsblol, SourceId.adsbfi]),
      );

      expect(polylines(tester), hasLength(2));
      expect(
        polylines(tester).map((line) => line.strokeWidth),
        everyElement(3.0),
      );
    });

    testWidgets('hides the legend behind the open sheet', (tester) async {
      await pumpMapScreen(
        tester,
        flights: [_airborneFlight(1)],
        trail: trailFrom([SourceId.adsblol, SourceId.adsbfi]),
      );

      await tester.drag(find.byType(FlightSheet), const Offset(0, -160));
      await tester.pump();

      expect(find.text('TRAIL BY SOURCE'), findsNothing);
    });
  });

  testWidgets('attributes the source it was switched to', (tester) async {
    final sourceSetting = await createTestSourceSetting();
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1)],
      sourceSetting: sourceSetting,
    );

    await sourceSetting.select(SourceId.adsbfi);
    await tester.pump();

    expect(
      find.text('© OpenStreetMap · © OpenMapTiles · Data: adsb.fi'),
      findsOneWidget,
    );
  });

  testWidgets('draws the reduced style', (tester) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1)],
      withVectorTiles: true,
    );

    expect(find.byType(VectorTileLayer), findsOneWidget);
  });

  testWidgets('swaps the tile layer when the style toggle is tapped', (
    tester,
  ) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1)],
      withVectorTiles: true,
    );

    await tester.tap(mapButtonWith(AppIcons.layerGroup));
    await tester.pump();

    expect(find.byType(VectorTileLayer), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is TileLayer && widget.urlTemplate != null,
      ),
      findsOneWidget,
    );
  });

  testWidgets('names the style toggle for screen readers', (tester) async {
    await pumpMapScreen(tester, flights: [_airborneFlight(1)]);

    expect(find.bySemanticsLabel('Switch map style'), findsOneWidget);
  });

  testWidgets('credits the tiles the switched style renders', (tester) async {
    await pumpMapScreen(tester, flights: [_airborneFlight(1)]);

    await tester.tap(mapButtonWith(AppIcons.layerGroup));
    await tester.pump();

    expect(find.text('© OpenStreetMap · Data: adsb.lol'), findsOneWidget);
  });

  testWidgets('frames the selected flight again when re-centering', (
    tester,
  ) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1, route: _frankfurtToNewYork)],
    );
    await settleCamera(tester);
    final framed = cameraOf(tester).center;

    await tester.drag(find.byType(FlutterMap), const Offset(-180, -180));
    await tester.pump();
    expect(cameraOf(tester).center, isNot(framed));

    await tester.tap(mapButtonWith(AppIcons.locationArrow));
    await settleCamera(tester);

    final recentered = cameraOf(tester).center;
    expect(recentered.latitude, closeTo(framed.latitude, 0.0001));
    expect(recentered.longitude, closeTo(framed.longitude, 0.0001));
  });

  testWidgets('names the re-center button for screen readers', (tester) async {
    await pumpMapScreen(tester, flights: [_airborneFlight(1)]);

    expect(find.bySemanticsLabel('Center on the flight'), findsOneWidget);
  });
}
