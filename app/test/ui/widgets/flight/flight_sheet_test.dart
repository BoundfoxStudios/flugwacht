import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/data/settings/source_setting.dart';
import 'package:flugwacht/data/settings/units_setting.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/map_style.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/units.dart';
import 'package:flugwacht/l10n/app_localization_delegates.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/list_sections.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/chrome/pager_dots.dart';
import 'package:flugwacht/ui/widgets/flight/flight_sheet.dart';
import 'package:flugwacht/ui/widgets/flight/flight_state_badge.dart';
import 'package:flugwacht/ui/widgets/flight/state_timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/test_dependencies.dart';

const _origin = RouteAirport(
  icaoCode: 'EDDF',
  iataCode: 'FRA',
  name: 'Frankfurt am Main',
  latitude: 50.026402,
  longitude: 8.543130,
);

const _route = FlightRoute(
  origin: _origin,
  destination: RouteAirport(
    icaoCode: 'KJFK',
    iataCode: 'JFK',
    name: 'New York JFK',
    location: 'New York',
    latitude: 40.639447,
    longitude: -73.779317,
  ),
);

const _routeWithoutCity = FlightRoute(
  origin: _origin,
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

/// The fixture position is 4257.5 km short of JFK, which its 473 kn cover in
/// 4 h 51 min 36 s.
const _timeToDestination = Duration(seconds: 17496);

String _deviceTime(
  DateTime arrival, {
  String pattern = 'h:mm a',
  String locale = 'en',
}) => DateFormat(pattern, locale).format(arrival.toLocal());

FlightListEntry _entry({
  int id = 1,
  FlightState state = FlightState.live,
  FlightRoute? route = _route,
  double? altitudeFeet = 37000,
  double? speedKnots = 473,
  DateTime? positionTime,
  DayTime? departureTime,
  bool withoutPosition = false,
}) => FlightListEntry(
  flight: Flight(
    id: id,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH40$id',
    departureDate: const CalendarDate(2026, 8, 12),
    departureTime: departureTime,
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

FlightListEntry _waitingEntry() =>
    _entry(state: FlightState.waiting, withoutPosition: true);

Future<List<int>> pumpFlightSheet(
  WidgetTester tester, {
  FlightListEntry? entry,
  List<FlightListEntry>? entries,
  int selectedIndex = 0,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  DateTime Function()? clock,
  SourceSetting? sourceSetting,
  UnitsSetting? unitsSetting,
  LiveActivityService? liveActivityService,
  void Function(Flight flight, {required bool isArmed})? onLiveActivityArmed,
}) async {
  final setting = sourceSetting ?? await createTestSourceSetting();
  final units = unitsSetting ?? await createTestUnitsSetting();
  final selections = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationDelegates,
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
            sourceSetting: setting,
            unitsSetting: units,
            mapStyle: MapStyle.reduced,
            liveActivityService:
                liveActivityService ?? createTestLiveActivityService(),
            onLiveActivityArmed:
                onLiveActivityArmed ?? (flight, {required isArmed}) {},
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
  testWidgets('peeks with the flight, its state and its arrival', (
    tester,
  ) async {
    await pumpFlightSheet(tester);

    final arrival = _positionTime.add(_timeToDestination);
    expect(find.text('LH401 · Anna & Ben'), findsOneWidget);
    expect(find.byType(FlightStateBadge), findsOneWidget);
    expect(find.text(_deviceTime(arrival)), findsOneWidget);
    expect(find.byType(StateTimeline), findsNothing);
    expect(find.text('Altitude'), findsNothing);
  });

  testWidgets('arrives in the viewer time, next to destination local time', (
    tester,
  ) async {
    await pumpFlightSheet(tester);

    final arrival = _positionTime.add(_timeToDestination);
    expect(find.text(_deviceTime(arrival)), findsOneWidget);
    expect(find.text('Arrival, your time'), findsOneWidget);
    expect(find.text('4 h 51 min left'), findsOneWidget);
    expect(find.text('Local time New York · 12:51 PM'), findsOneWidget);
  });

  /// The detail is the last line of the arrival block and shares the baseline
  /// of the arrival time, so the block ends where the digits do.
  testWidgets('closes the arrival block on the baseline of the time', (
    tester,
  ) async {
    await pumpFlightSheet(tester);

    final time = find.text(_deviceTime(_positionTime.add(_timeToDestination)));
    final label = find.text('Arrival, your time');
    final detail = find.text('4 h 51 min left');
    expect(
      tester.getBottomLeft(label).dy,
      lessThanOrEqualTo(tester.getTopLeft(detail).dy),
    );
    expect(
      tester.getBottomLeft(detail).dy,
      lessThanOrEqualTo(tester.getBottomLeft(time).dy),
    );
  });

  testWidgets('names the destination airport when it has no city', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _entry(route: _routeWithoutCity));

    expect(find.textContaining('Local time New York JFK · '), findsOneWidget);
  });

  testWidgets('counts the remaining time down', (tester) async {
    var now = _now;
    await pumpFlightSheet(tester, clock: () => now);
    expect(find.text('4 h 51 min left'), findsOneWidget);

    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('4 h 50 min left'), findsOneWidget);
  });

  testWidgets('freezes the arrival of a flight without signal', (tester) async {
    final positionTime = _now.subtract(const Duration(minutes: 42));
    await pumpFlightSheet(
      tester,
      entry: _entry(state: FlightState.noSignal, positionTime: positionTime),
    );

    final frozenArrival = positionTime.add(_timeToDestination);
    expect(find.text('~${_deviceTime(frozenArrival)}'), findsOneWidget);
    expect(find.text('As of 42 min ago'), findsOneWidget);
    expect(find.textContaining('left'), findsNothing);
    expect(find.textContaining('Local time New York · '), findsOneWidget);
  });

  testWidgets('keeps the placeholder while the route is unknown', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _entry(route: null));

    expect(find.text('–:–'), findsOneWidget);
    expect(find.text('Arrival, your time'), findsNothing);
    expect(find.textContaining('Local time'), findsNothing);
  });

  testWidgets('keeps the placeholder while the flight still taxis', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _entry(speedKnots: 30));

    expect(find.text('–:–'), findsOneWidget);
    expect(find.text('Arrival, your time'), findsNothing);
  });

  testWidgets('arrives in german copy and clock format', (tester) async {
    await pumpFlightSheet(tester, locale: const Locale('de'));

    final arrival = _positionTime.add(_timeToDestination);
    expect(
      find.text(_deviceTime(arrival, pattern: 'HH:mm', locale: 'de')),
      findsOneWidget,
    );
    expect(find.text('Ankunft bei dir'), findsOneWidget);
    expect(find.text('noch 4 Std 51 Min'), findsOneWidget);
    expect(find.text('Ortszeit New York · 12:51'), findsOneWidget);
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

  testWidgets('follows the units setting into feet and knots', (tester) async {
    final unitsSetting = await createTestUnitsSetting();
    await pumpFlightSheet(tester, unitsSetting: unitsSetting);

    await openSheet(tester);
    expect(find.text('11,278 m'), findsOneWidget);

    await unitsSetting.select(Units.aviation);
    await tester.pumpAndSettle();

    expect(find.text('37,000 ft'), findsOneWidget);
    expect(find.text('473 kt'), findsOneWidget);
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

  testWidgets('tells a waiting flight what it searches for', (tester) async {
    await pumpFlightSheet(tester, entry: _waitingEntry());

    await openSheet(tester);

    expect(
      find.text(
        'Searching for LH401. Receivers are often missing for one to two '
        'hours, the trail starts as soon as one sees the aircraft.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tells a waiting flight what it searches for in german', (
    tester,
  ) async {
    await pumpFlightSheet(
      tester,
      locale: const Locale('de'),
      entry: _waitingEntry(),
    );

    await openSheet(tester);

    expect(
      find.text(
        'Sucht nach LH401. Oft fehlen ein bis zwei Stunden lang Empfänger, '
        'die Spur beginnt, sobald einer das Flugzeug sieht.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the waiting explanation out of the peek', (tester) async {
    await pumpFlightSheet(tester, entry: _waitingEntry());

    expect(find.textContaining('Searching for'), findsNothing);
  });

  testWidgets('keeps the gap explanations off a live flight', (tester) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);

    expect(find.textContaining('the trail will come back'), findsNothing);
    expect(find.textContaining('Searching for'), findsNothing);
  });

  testWidgets('states the foreground limit on an open live flight', (
    tester,
  ) async {
    await pumpFlightSheet(tester);

    await openSheet(tester);

    expect(
      find.text('The trail only grows while Flugwacht is open'),
      findsOneWidget,
    );
  });

  testWidgets('states the foreground limit in German', (tester) async {
    await pumpFlightSheet(tester, locale: const Locale('de'));

    await openSheet(tester);

    expect(
      find.text('Die Spur wächst nur, solange Flugwacht offen ist'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the foreground limit out of the peek', (tester) async {
    await pumpFlightSheet(tester);

    expect(
      find.textContaining('only grows while Flugwacht is open'),
      findsNothing,
    );
  });

  testWidgets('leaves a missing signal its own explanation', (tester) async {
    await pumpFlightSheet(tester, entry: _entry(state: FlightState.noSignal));

    await openSheet(tester);

    expect(find.textContaining('the trail will come back'), findsOneWidget);
    expect(
      find.textContaining('only grows while Flugwacht is open'),
      findsNothing,
    );
  });

  testWidgets('says nothing about a trail that has not started', (
    tester,
  ) async {
    await pumpFlightSheet(tester, entry: _waitingEntry());

    await openSheet(tester);

    expect(find.textContaining('Searching for'), findsOneWidget);
    expect(
      find.textContaining('only grows while Flugwacht is open'),
      findsNothing,
    );
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

    expect(
      find.text('Source: adsb.fi · © OpenStreetMap · © OpenMapTiles'),
      findsOneWidget,
    );
  });

  group('try another source', () {
    Finder linkTapTarget() => find.ancestor(
      of: find.text('Try another source'),
      matching: find.byType(GestureDetector),
    );

    testWidgets('offers another source to a flight without signal', (
      tester,
    ) async {
      await pumpFlightSheet(tester, entry: _entry(state: FlightState.noSignal));

      await openSheet(tester);

      expect(find.text('Try another source'), findsOneWidget);
    });

    testWidgets('offers another source to a waiting flight', (tester) async {
      await pumpFlightSheet(tester, entry: _waitingEntry());

      await openSheet(tester);

      expect(find.text('Try another source'), findsOneWidget);
    });

    testWidgets('offers no other source while the signal is there', (
      tester,
    ) async {
      await pumpFlightSheet(tester);

      await openSheet(tester);

      expect(find.text('Try another source'), findsNothing);
    });

    testWidgets('keeps the link out of the peek', (tester) async {
      await pumpFlightSheet(tester, entry: _entry(state: FlightState.noSignal));

      expect(find.text('Try another source'), findsNothing);
    });

    testWidgets('switches to the next source on a tap', (tester) async {
      final sourceSetting = await createTestSourceSetting();
      await pumpFlightSheet(
        tester,
        entry: _entry(state: FlightState.noSignal),
        sourceSetting: sourceSetting,
      );
      await openSheet(tester);

      await tester.tap(linkTapTarget().first);
      await tester.pumpAndSettle();

      expect(sourceSetting.activeId.value, SourceId.adsblol);
      expect(
        find.text('Source: adsb.lol · © OpenStreetMap · © OpenMapTiles'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the link tappable at 44 pixels', (tester) async {
      await pumpFlightSheet(tester, entry: _entry(state: FlightState.noSignal));

      await openSheet(tester);

      expect(
        tester.getSize(linkTapTarget().first).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('offers another source in German as well', (tester) async {
      await pumpFlightSheet(
        tester,
        entry: _entry(state: FlightState.noSignal),
        locale: const Locale('de'),
      );

      await openSheet(tester);

      expect(find.text('Andere Quelle probieren'), findsOneWidget);
    });
  });

  testWidgets('names the source it was switched to', (tester) async {
    final sourceSetting = await createTestSourceSetting();
    await pumpFlightSheet(tester, sourceSetting: sourceSetting);
    await openSheet(tester);

    await sourceSetting.select(SourceId.adsblol);
    await tester.pump();

    expect(
      find.text('Source: adsb.lol · © OpenStreetMap · © OpenMapTiles'),
      findsOneWidget,
    );
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

  group('live activity', () {
    testWidgets('offers no switch where the device shows no activities', (
      tester,
    ) async {
      final service = createTestLiveActivityService();
      service.availability.value = LiveActivityAvailability.unsupported;
      await pumpFlightSheet(tester, liveActivityService: service);
      await openSheet(tester);

      expect(find.text('On the lock screen on flight day'), findsNothing);
    });

    testWidgets('arms the flight the sheet shows', (tester) async {
      final armings = <(int, bool)>[];
      await pumpFlightSheet(
        tester,
        onLiveActivityArmed: (flight, {required isArmed}) =>
            armings.add((flight.id, isArmed)),
      );
      await openSheet(tester);

      await tester.tap(find.text('On the lock screen on flight day'));
      await tester.pumpAndSettle();

      expect(armings, [(1, true)]);
    });
  });
}
