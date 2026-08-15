import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/list_sections.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/flight_sheet.dart';
import 'package:flugwacht/ui/widgets/flight_state_badge.dart';
import 'package:flugwacht/ui/widgets/state_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

FlightListEntry _entry({
  FlightState state = FlightState.live,
  FlightRoute? route = _route,
  double? altitudeFeet = 37000,
  double? speedKnots = 473,
}) => FlightListEntry(
  flight: Flight(
    id: 1,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH400',
    departureDate: const CalendarDate(2026, 8, 12),
    note: 'Anna & Ben',
    route: route,
    tracking: FlightTracking(
      latestPosition: FixPosition(
        latitude: 48.5,
        longitude: -20,
        timestamp: DateTime.utc(2026, 8, 12, 12),
        barometricAltitudeFeet: altitudeFeet,
        groundSpeedKnots: speedKnots,
      ),
      hasBeenAirborne: true,
    ),
  ),
  state: state,
);

Future<void> pumpFlightSheet(
  WidgetTester tester, {
  FlightListEntry? entry,
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
        body: Align(
          alignment: Alignment.bottomCenter,
          child: FlightSheet(entry: entry ?? _entry()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.drag(find.byType(FlightSheet), const Offset(0, -160));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('peeks with the flight, its state and the arrival placeholder', (
    tester,
  ) async {
    await pumpFlightSheet(tester);

    expect(find.text('LH400 · Anna & Ben'), findsOneWidget);
    expect(find.byType(FlightStateBadge), findsOneWidget);
    expect(find.text('–:–'), findsOneWidget);
    expect(find.byType(StateTimeline), findsNothing);
    expect(find.text('Altitude'), findsNothing);
  });

  testWidgets('opens on a drag and closes again', (tester) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);
    expect(find.byType(StateTimeline), findsOneWidget);

    await tester.drag(find.byType(FlightSheet), const Offset(0, 160));
    await tester.pumpAndSettle();

    expect(find.byType(StateTimeline), findsNothing);
  });

  testWidgets('opens on a tap on the grabber', (tester) async {
    await pumpFlightSheet(tester);
    final sheet = tester.getRect(find.byType(FlightSheet));

    await tester.tapAt(Offset(sheet.center.dx, sheet.top + 10));
    await tester.pumpAndSettle();

    expect(find.byType(StateTimeline), findsOneWidget);
  });

  testWidgets('trades the badge for the route once open', (tester) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);

    expect(find.text('FRA → JFK'), findsOneWidget);
    expect(find.byType(FlightStateBadge), findsNothing);
  });

  testWidgets('keeps the badge open while the flight has no signal', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _entry(state: FlightState.noSignal));

    await openSheet(tester);

    expect(find.byType(FlightStateBadge), findsOneWidget);
    expect(find.text('FRA → JFK'), findsNothing);
  });

  testWidgets('keeps the badge open while the route is unknown', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _entry(route: null));

    await openSheet(tester);

    expect(find.byType(FlightStateBadge), findsOneWidget);
  });

  testWidgets('shows altitude and speed in metric units', (tester) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);

    expect(find.text('11,278 m'), findsOneWidget);
    expect(find.text('876 km/h'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
  });

  testWidgets('groups the numbers the German way', (tester) async {
    await pumpFlightSheet(tester, locale: const Locale('de'));

    await openSheet(tester);

    expect(find.text('11.278 m'), findsOneWidget);
    expect(find.text('Höhe'), findsOneWidget);
  });

  testWidgets('dashes every column the flight has no numbers for', (
    tester,
  ) async {
    await pumpFlightSheet(
      tester,
      entry: _entry(altitudeFeet: null, speedKnots: null),
    );

    await openSheet(tester);

    expect(find.text('–'), findsNWidgets(3));
  });

  testWidgets('times the flight on the timeline it is on', (tester) async {
    await pumpFlightSheet(tester, entry: _entry(state: FlightState.noSignal));

    await openSheet(tester);

    expect(
      tester.widget<StateTimeline>(find.byType(StateTimeline)).state,
      FlightState.noSignal,
    );
  });

  testWidgets('names the source it flies on', (tester) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);

    expect(find.text('Source: adsb.lol · © OpenStreetMap'), findsOneWidget);
  });
}
