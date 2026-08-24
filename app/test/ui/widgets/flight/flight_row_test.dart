import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/l10n/app_localization_delegates.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/flight/flight_row.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

const _rowKey = ValueKey('row');
const _rowWidth = 320.0;

/// The test font renders every glyph a full em wide, so the two-clock
/// accessory needs more room here than the design gives it on a phone.
const _wideRowWidth = 640.0;

const _route = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDS',
    iataCode: 'STR',
    name: 'Stuttgart',
    latitude: 48.690003,
    longitude: 9.221964,
  ),
  destination: RouteAirport(
    icaoCode: 'LEPA',
    iataCode: 'PMI',
    name: 'Palma de Mallorca',
    latitude: 39.551700,
    longitude: 2.738810,
  ),
);

const _taipeiRoute = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'RCTP',
    iataCode: 'TPE',
    name: 'Taiwan Taoyuan',
    latitude: 25.0777,
    longitude: 121.2328,
  ),
  destination: RouteAirport(
    icaoCode: 'WIII',
    iataCode: 'CGK',
    name: 'Jakarta Soekarno-Hatta',
    latitude: -6.1256,
    longitude: 106.6558,
  ),
);

Flight flight({
  String lookupValue = 'EW594',
  String? note,
  FlightRoute? route = _route,
  CalendarDate date = const CalendarDate(2026, 8, 15),
  DayTime? time,
  DepartureTimeInterpretation interpretation =
      DepartureTimeInterpretation.device,
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: lookupValue,
  departureDate: date,
  departureTime: time,
  departureTimeInterpretation: interpretation,
  note: note,
  route: route,
);

Future<void> pumpRow(
  WidgetTester tester, {
  required FlightState state,
  Flight? row,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  DateTime? now,
  double width = _rowWidth,
}) => tester.pumpWidget(
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
          key: _rowKey,
          child: SizedBox(
            width: width,
            child: ColoredBox(
              color: switch (brightness) {
                Brightness.light => AppColors.neutral50,
                Brightness.dark => AppColors.neutral900,
              },
              child: FlightRow(
                flight: row ?? flight(),
                state: state,
                now: now ?? DateTime(2026, 8, 15, 18),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Color? colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

Future<Color> cardColor(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_rowKey),
  );
  final pixels = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    return (await image.toByteData())!;
  }))!;
  const inspected = Offset(_rowWidth / 2, 5);
  final offset =
      (inspected.dy.toInt() * _rowWidth.toInt() + inspected.dx.toInt()) * 4;
  return Color.fromARGB(
    pixels.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
}

void main() {
  testWidgets('shows route, state and today on a waiting row', (tester) async {
    await pumpRow(
      tester,
      state: FlightState.waiting,
      row: flight(note: 'Mama'),
    );

    expect(find.text('EW594 · Mama'), findsOneWidget);
    expect(find.text('STR → PMI · waiting for signal'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(colorOf(tester, 'EW594 · Mama'), AppColors.neutral700);
    expect(
      colorOf(tester, 'STR → PMI · waiting for signal'),
      AppColors.neutral500,
    );
    expect(colorOf(tester, 'today'), AppColors.neutral500);
  });

  testWidgets('shows the scheduled departure time on a waiting row', (
    tester,
  ) async {
    await pumpRow(
      tester,
      state: FlightState.waiting,
      row: flight(time: const DayTime(16, 10)),
    );

    expect(find.text('from 4:10 PM'), findsOneWidget);
    expect(find.text('today'), findsNothing);
  });

  testWidgets('shows an origin-local departure in both clocks', (tester) async {
    await pumpRow(
      tester,
      state: FlightState.waiting,
      width: _wideRowWidth,
      row: flight(
        time: const DayTime(16, 10),
        interpretation: DepartureTimeInterpretation.originLocal,
        route: _taipeiRoute,
      ),
    );

    final deviceTime = DateFormat(
      'h:mm a',
      'en',
    ).format(DateTime.utc(2026, 8, 15, 8, 10).toLocal());
    expect(find.text('from $deviceTime · 4:10 PM local'), findsOneWidget);
  });

  testWidgets('keeps the plain date on a planned row with a time', (
    tester,
  ) async {
    await pumpRow(
      tester,
      state: FlightState.planned,
      row: flight(time: const DayTime(16, 10)),
    );

    expect(find.text('Sat, Aug 15'), findsOneWidget);
  });

  testWidgets('draws the waiting row on the card surface', (tester) async {
    await pumpRow(tester, state: FlightState.waiting);

    expect(await cardColor(tester), AppColors.white);
  });

  testWidgets('shows the planned row one step lighter with its date', (
    tester,
  ) async {
    await pumpRow(tester, state: FlightState.planned);

    expect(find.text('STR → PMI · planned'), findsOneWidget);
    expect(find.text('Sat, Aug 15'), findsOneWidget);
    expect(colorOf(tester, 'EW594'), AppColors.neutral500);
    expect(colorOf(tester, 'STR → PMI · planned'), AppColors.neutral400);
    expect(colorOf(tester, 'Sat, Aug 15'), AppColors.neutral400);
  });

  testWidgets('lets the page background through the planned row', (
    tester,
  ) async {
    await pumpRow(tester, state: FlightState.planned);

    expect(await cardColor(tester), AppColors.neutral50);
  });

  testWidgets('grays a landed flight and drops the state from the subtitle', (
    tester,
  ) async {
    await pumpRow(tester, state: FlightState.ended);

    expect(find.text('STR → PMI · today'), findsOneWidget);
    expect(find.text('landed ✓'), findsOneWidget);
    expect(colorOf(tester, 'EW594'), AppColors.neutral400);
    expect(colorOf(tester, 'STR → PMI · today'), AppColors.neutral400);
    expect(colorOf(tester, 'landed ✓'), AppColors.neutral400);
  });

  testWidgets('names yesterday as the departure day of a past row', (
    tester,
  ) async {
    await pumpRow(
      tester,
      state: FlightState.ended,
      now: DateTime(2026, 8, 16, 2),
    );

    expect(find.text('STR → PMI · yesterday'), findsOneWidget);
  });

  testWidgets('dates a past row that survived beyond yesterday', (
    tester,
  ) async {
    await pumpRow(
      tester,
      state: FlightState.missed,
      now: DateTime(2026, 8, 17, 9),
    );

    expect(find.text('STR → PMI · Sat, Aug 15'), findsOneWidget);
  });

  testWidgets('marks a missed flight as missed', (tester) async {
    await pumpRow(tester, state: FlightState.missed);

    expect(find.text('missed'), findsOneWidget);
  });

  testWidgets(
    'leaves the day as the only subtitle of a past row without route',
    (tester) async {
      await pumpRow(tester, state: FlightState.ended, row: flight(route: null));

      expect(find.text('EW594'), findsOneWidget);
      expect(find.text('today'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(3));
    },
  );

  testWidgets('keeps the state as the only subtitle without a route', (
    tester,
  ) async {
    await pumpRow(tester, state: FlightState.waiting, row: flight(route: null));

    expect(find.text('waiting for signal'), findsOneWidget);
  });

  testWidgets('shows the lookup value of a hex flight', (tester) async {
    await pumpRow(
      tester,
      state: FlightState.waiting,
      row: flight(lookupValue: '3c6444', route: null),
    );

    expect(find.text('3c6444'), findsOneWidget);
  });

  testWidgets('truncates an overlong note without pushing out the accessory', (
    tester,
  ) async {
    await pumpRow(tester, state: FlightState.waiting);
    final accessoryWidth = tester.getSize(find.text('today')).width;
    final titleHeight = tester.getSize(find.text('EW594')).height;

    await pumpRow(
      tester,
      state: FlightState.waiting,
      row: flight(note: 'Anna & Ben ${'and everyone else ' * 10}'),
    );

    final title = find.textContaining('Anna & Ben');
    expect(
      tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
      isTrue,
    );
    expect(tester.getSize(title).height, titleHeight);
    expect(tester.getSize(find.text('today')).width, accessoryWidth);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpRow(
      tester,
      state: FlightState.waiting,
      locale: const Locale('de'),
    );
    expect(find.text('STR → PMI · wartet auf Signal'), findsOneWidget);
    expect(find.text('heute'), findsOneWidget);
    await pumpRow(
      tester,
      state: FlightState.waiting,
      row: flight(time: const DayTime(16, 10)),
      locale: const Locale('de'),
    );
    expect(find.text('ab 16:10'), findsOneWidget);

    await pumpRow(
      tester,
      state: FlightState.planned,
      locale: const Locale('de'),
    );
    expect(find.text('STR → PMI · geplant'), findsOneWidget);
    expect(find.text('Sa, 15. Aug'), findsOneWidget);

    await pumpRow(
      tester,
      state: FlightState.ended,
      locale: const Locale('de'),
      now: DateTime(2026, 8, 16, 2),
    );
    expect(find.text('gelandet ✓'), findsOneWidget);
    expect(find.text('STR → PMI · gestern'), findsOneWidget);

    await pumpRow(
      tester,
      state: FlightState.missed,
      locale: const Locale('de'),
    );
    expect(find.text('verpasst'), findsOneWidget);
  });

  testWidgets('lightens the row texts in the dark theme', (tester) async {
    await pumpRow(
      tester,
      state: FlightState.waiting,
      brightness: Brightness.dark,
    );

    expect(colorOf(tester, 'EW594'), AppColors.neutral300);
    expect(
      colorOf(tester, 'STR → PMI · waiting for signal'),
      AppColors.neutral400,
    );
    expect(await cardColor(tester), AppColors.neutral800);
  });
}
