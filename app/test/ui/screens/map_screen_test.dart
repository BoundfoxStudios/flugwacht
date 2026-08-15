import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/map_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/map_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

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
}) => Flight(
  id: id,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH40$id',
  departureDate: _departureDate,
  route: route,
  tracking: FlightTracking(
    latestPosition: FixPosition(
      latitude: 48.5,
      longitude: -20,
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
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  final repository = FakeFlightRepository();
  addTearDown(repository.dispose);
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
        clock: () => _now,
        tileProvider: StubTileProvider(),
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
  return repository;
}

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
    expect(tester.takeException(), isNull);
  });

  testWidgets('attributes OpenStreetMap and the active source', (tester) async {
    await pumpMapScreen(tester, flights: [_airborneFlight(1)]);

    expect(find.text('© OpenStreetMap · Data: adsb.lol'), findsOneWidget);
  });

  testWidgets('attributes in German as well', (tester) async {
    await pumpMapScreen(
      tester,
      flights: [_airborneFlight(1)],
      locale: const Locale('de'),
    );

    expect(find.text('© OpenStreetMap · Daten: adsb.lol'), findsOneWidget);
  });
}
