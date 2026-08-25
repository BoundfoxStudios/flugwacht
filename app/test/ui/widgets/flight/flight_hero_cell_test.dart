import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/l10n/app_localization_delegates.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/flight/flight_hero_cell.dart';
import 'package:flugwacht/ui/widgets/flight/state_timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/rendered_pixels.dart';
import '../../../support/test_dependencies.dart';

const _cellKey = ValueKey('cell');
const _cellWidth = 360.0;

/// The test font renders every glyph a full em wide, so the arrival line needs
/// more room here than the design gives it on a phone.
const _wideCellWidth = 900.0;

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

Flight flight({
  String? note = 'Anna & Ben',
  FlightRoute? route = _route,
  double? speedKnots,
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH400',
  departureDate: const CalendarDate(2026, 8, 12),
  note: note,
  route: route,
  tracking: FlightTracking(
    latestPosition: FixPosition(
      latitude: 48.5,
      longitude: -20,
      timestamp: _positionTime,
      trackDegrees: 271.4,
      groundSpeedKnots: speedKnots,
    ),
    hasBeenAirborne: true,
  ),
);

Future<void> pumpHeroCell(
  WidgetTester tester, {
  FlightState state = FlightState.live,
  Flight? cell,
  List<TrailPoint> trail = const [],
  VoidCallback? onTap,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double width = _cellWidth,
}) async {
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
        body: Center(
          child: RepaintBoundary(
            key: _cellKey,
            child: SizedBox(
              width: width,
              child: FlightHeroCell(
                flight: cell ?? flight(),
                state: state,
                trail: trail,
                now: _now,
                onTap: onTap,
                mapStyleSetting: await createTestMapStyleSetting(),
                tileSources: testTileSources(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

BoxDecoration badgeDecoration(WidgetTester tester, String label) =>
    tester
            .widget<Container>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

double pressDip(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(FlightHeroCell),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getTranslation()
    .y;

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

  testWidgets('lightens the no-signal label in the dark theme', (tester) async {
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

  testWidgets('renders no arrival block without an estimate', (tester) async {
    await pumpHeroCell(tester);

    expect(
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
      unorderedEquals([
        'LH400 · Anna & Ben',
        'FRA → JFK',
        'LIVE',
        'FRA',
        'JFK',
        '© OpenStreetMap · © OpenMapTiles',
      ]),
    );
  });

  testWidgets('shows the arrival of a live flight in one line', (tester) async {
    await pumpHeroCell(
      tester,
      cell: flight(speedKnots: 473),
      width: _wideCellWidth,
    );

    final arrival = _positionTime.add(const Duration(seconds: 17496));
    expect(
      find.text(DateFormat('h:mm a', 'en').format(arrival.toLocal())),
      findsOneWidget,
    );
    expect(find.text('Arrival, your time · 4 h 51 min left'), findsOneWidget);
  });

  testWidgets('freezes the arrival of a flight without signal', (tester) async {
    await pumpHeroCell(
      tester,
      state: FlightState.noSignal,
      cell: flight(speedKnots: 473),
      locale: const Locale('de'),
      width: _wideCellWidth,
    );

    final arrival = _positionTime.add(const Duration(seconds: 17496));
    expect(
      find.text('~${DateFormat('HH:mm', 'de').format(arrival.toLocal())}'),
      findsOneWidget,
    );
    expect(find.text('Ankunft bei dir · Stand: vor 3 s'), findsOneWidget);
  });

  testWidgets('fills the live badge and leaves it without a border', (
    tester,
  ) async {
    await pumpHeroCell(tester);

    final badge = badgeDecoration(tester, 'LIVE');
    expect(badge.color, AppColors.yellow);
    expect(badge.border, isNull);
  });

  testWidgets('fills the no-signal badge in the light theme', (tester) async {
    await pumpHeroCell(tester, state: FlightState.noSignal);

    final badge = badgeDecoration(tester, 'NO SIGNAL');
    expect(badge.color, AppColors.neutral700);
    expect(badge.border, isNull);
  });

  testWidgets('outlines the no-signal badge in the dark theme', (tester) async {
    await pumpHeroCell(
      tester,
      state: FlightState.noSignal,
      brightness: Brightness.dark,
    );

    final badge = badgeDecoration(tester, 'NO SIGNAL');
    expect(badge.color, isNull);
    expect(badge.border?.top.color, AppColors.neutral500);
  });

  testWidgets('keeps its border visible next to the mini map', (tester) async {
    await pumpHeroCell(tester);

    final pixels = await renderedPixels(tester, _cellKey);
    expect(pixels.at(const Offset(0, 60)), AppColors.neutral200);
  });

  testWidgets('credits OpenStreetMap on the map', (tester) async {
    await pumpHeroCell(tester);

    expect(find.text('© OpenStreetMap · © OpenMapTiles'), findsOneWidget);
  });

  testWidgets('dips while pressed and opens the flight on release', (
    tester,
  ) async {
    var taps = 0;
    await pumpHeroCell(tester, onTap: () => taps++);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FlightHeroCell)),
    );
    await tester.pump();
    expect(pressDip(tester), 1);

    await gesture.up();
    await tester.pump();

    expect(taps, 1);
    expect(pressDip(tester), 0);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpHeroCell(
      tester,
      state: FlightState.noSignal,
      locale: const Locale('de'),
    );

    expect(find.text('KEIN SIGNAL'), findsOneWidget);
    expect(find.text('© OpenStreetMap · © OpenMapTiles'), findsOneWidget);
  });
}
