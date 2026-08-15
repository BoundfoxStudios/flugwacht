import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/l10n/app_localizations.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/flight_hero_cell.dart';
import 'package:flugwacht/ui/widgets/mini_map.dart';
import 'package:flugwacht/ui/widgets/state_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../support/test_dependencies.dart';

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

Flight flight({String? note = 'Anna & Ben', FlightRoute? route = _route}) =>
    Flight(
      id: 1,
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH400',
      departureDate: const CalendarDate(2026, 8, 12),
      note: note,
      route: route,
      tracking: FlightTracking(
        latestPosition: _position,
        hasBeenAirborne: true,
      ),
    );

Future<void> pumpHeroCell(
  WidgetTester tester, {
  FlightState state = FlightState.live,
  Flight? cell,
  List<TrailPoint> trail = const [],
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: FlightHeroCell(
              flight: cell ?? flight(),
              state: state,
              trail: trail,
              tileProvider: StubTileProvider(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('heads the cell with the lookup value, note and route', (
    tester,
  ) async {
    await pumpHeroCell(tester);

    expect(find.text('LH400 · Anna & Ben'), findsOneWidget);
    expect(find.text('FRA → JFK'), findsOneWidget);
  });

  testWidgets('leaves out note and route when the flight has neither', (
    tester,
  ) async {
    await pumpHeroCell(tester, cell: flight(note: null, route: null));

    expect(find.text('LH400'), findsOneWidget);
    expect(find.textContaining('→'), findsNothing);
  });

  testWidgets('badges a live flight in yellow', (tester) async {
    await pumpHeroCell(tester);

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('NO SIGNAL'), findsNothing);
    expect(
      tester.widget<Text>(find.text('LIVE')).style?.color,
      AppColors.neutral900,
    );
  });

  testWidgets('badges a flight without a signal', (tester) async {
    await pumpHeroCell(tester, state: FlightState.noSignal);

    expect(find.text('NO SIGNAL'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('NO SIGNAL')).style?.color,
      AppColors.yellow,
    );
  });

  testWidgets('outlines the no-signal badge in the dark theme', (tester) async {
    await pumpHeroCell(
      tester,
      state: FlightState.noSignal,
      brightness: Brightness.dark,
    );

    expect(
      tester.widget<Text>(find.text('NO SIGNAL')).style?.color,
      AppColors.neutral300,
    );
  });

  testWidgets('shows the compact timeline of the current state', (
    tester,
  ) async {
    await pumpHeroCell(tester, state: FlightState.noSignal);

    final timeline = tester.widget<StateTimeline>(find.byType(StateTimeline));
    expect(timeline.state, FlightState.noSignal);
    expect(timeline.variant, StateTimelineVariant.compact);
    expect(find.bySemanticsLabel('no signal'), findsOneWidget);
  });

  testWidgets('renders no arrival estimate yet', (tester) async {
    await pumpHeroCell(tester);

    final sizes = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.style?.fontSize ?? 0);
    expect(sizes, everyElement(lessThan(20)));
  });

  testWidgets('credits OpenStreetMap on the map', (tester) async {
    await pumpHeroCell(tester);

    expect(find.text('© OpenStreetMap'), findsOneWidget);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpHeroCell(
      tester,
      state: FlightState.noSignal,
      locale: const Locale('de'),
    );

    expect(find.text('KEIN SIGNAL'), findsOneWidget);
    expect(find.text('© OpenStreetMap'), findsOneWidget);
  });

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
      miniMapFocusPoints(position: _position, route: _route, trail: trail),
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
      miniMapFocusPoints(position: _position, route: null, trail: const []),
      [const LatLng(48.5, -20)],
    );
  });
}
