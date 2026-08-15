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
import 'package:flugwacht/ui/widgets/pager_dots.dart';
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

final _positionTime = DateTime.utc(2026, 8, 12, 12);
final _now = _positionTime.add(const Duration(seconds: 3));

FlightListEntry _entry({
  int id = 1,
  FlightState state = FlightState.live,
  FlightRoute? route = _route,
  double? altitudeFeet = 37000,
  double? speedKnots = 473,
  DateTime? positionTime,
  bool withoutPosition = false,
}) => FlightListEntry(
  flight: Flight(
    id: id,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH40$id',
    departureDate: const CalendarDate(2026, 8, 12),
    note: 'Anna & Ben',
    route: route,
    tracking: FlightTracking(
      latestPosition: withoutPosition
          ? null
          : FixPosition(
              latitude: 48.5,
              longitude: -20,
              timestamp: positionTime ?? _positionTime,
              barometricAltitudeFeet: altitudeFeet,
              groundSpeedKnots: speedKnots,
            ),
      hasBeenAirborne: true,
    ),
  ),
  state: state,
);

Future<List<int>> pumpFlightSheet(
  WidgetTester tester, {
  FlightListEntry? entry,
  List<FlightListEntry>? entries,
  int selectedIndex = 0,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  DateTime Function()? clock,
}) async {
  final selections = <int>[];
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
          child: FlightSheet(
            entries: entries ?? [entry ?? _entry()],
            selectedIndex: selectedIndex,
            onSelected: selections.add,
            clock: clock ?? () => _now,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return selections;
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

    expect(find.text('LH401 · Anna & Ben'), findsOneWidget);
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
    expect(find.text('3 s ago'), findsOneWidget);
  });

  testWidgets('counts the signal age up every second', (tester) async {
    var now = _now;
    await pumpFlightSheet(tester, clock: () => now);

    await openSheet(tester);
    expect(find.text('3 s ago'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('4 s ago'), findsOneWidget);
  });

  testWidgets('explains a signal gap without dropping the last numbers', (
    tester,
  ) async {
    await pumpFlightSheet(
      tester,
      entry: _entry(
        state: FlightState.noSignal,
        positionTime: _now.subtract(const Duration(minutes: 42)),
      ),
    );

    await openSheet(tester);

    expect(find.text('42 min ago'), findsOneWidget);
    expect(find.textContaining('Last signal 42 min ago.'), findsOneWidget);
    expect(find.textContaining('the trail will come back'), findsOneWidget);
    expect(find.text('11,278 m'), findsOneWidget);
    expect(find.text('876 km/h'), findsOneWidget);
  });

  testWidgets('explains a signal gap in german', (tester) async {
    await pumpFlightSheet(
      tester,
      locale: const Locale('de'),
      entry: _entry(
        state: FlightState.noSignal,
        positionTime: _now.subtract(const Duration(hours: 2, minutes: 5)),
      ),
    );

    await openSheet(tester);

    expect(find.text('vor 2 Std 5 Min'), findsOneWidget);
    expect(
      find.textContaining('Letztes Signal vor 2 Std 5 Min.'),
      findsOneWidget,
    );
  });

  testWidgets('explains nothing while the signal is live', (tester) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);

    expect(find.textContaining('the trail will come back'), findsNothing);
  });

  testWidgets('dashes the signal of a flight without a position', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _entry(withoutPosition: true));

    await openSheet(tester);

    expect(find.text('–'), findsNWidgets(3));
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

    expect(find.text('–'), findsNWidgets(2));
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

  testWidgets('reports the flight it was swiped to', (tester) async {
    final selections = await pumpFlightSheet(
      tester,
      entries: [_entry(), _entry(id: 2)],
    );

    await tester.drag(find.byType(FlightSheet), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(selections, [1]);
  });

  testWidgets('pages to a flight that was selected elsewhere', (tester) async {
    await pumpFlightSheet(tester, entries: [_entry(), _entry(id: 2)]);
    final pages = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(pages.controller!.offset, 0);

    await pumpFlightSheet(
      tester,
      entries: [_entry(), _entry(id: 2)],
      selectedIndex: 1,
    );

    expect(pages.controller!.offset, greaterThan(0));
  });

  testWidgets('dots the pages only from two flights on', (tester) async {
    await pumpFlightSheet(tester);
    expect(find.byType(PagerDots), findsNothing);

    await pumpFlightSheet(
      tester,
      entries: [_entry(), _entry(id: 2)],
      selectedIndex: 1,
    );

    expect(tester.widget<PagerDots>(find.byType(PagerDots)).activeIndex, 1);
  });
}
