import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/l10n/app_localizations.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/flight_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _rowKey = ValueKey('row');
const _rowWidth = 320.0;

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

Flight flight({
  String lookupValue = 'EW594',
  String? note,
  FlightRoute? route = _route,
  CalendarDate date = const CalendarDate(2026, 8, 15),
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: lookupValue,
  departureDate: date,
  note: note,
  route: route,
);

Future<void> pumpRow(
  WidgetTester tester, {
  required FlightState state,
  Flight? row,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) => tester.pumpWidget(
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
        child: RepaintBoundary(
          key: _rowKey,
          child: SizedBox(
            width: _rowWidth,
            child: ColoredBox(
              color: switch (brightness) {
                Brightness.light => AppColors.neutral50,
                Brightness.dark => AppColors.neutral900,
              },
              child: FlightRow(flight: row ?? flight(), state: state),
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

    expect(find.text('STR → PMI'), findsOneWidget);
    expect(find.text('landed ✓'), findsOneWidget);
    expect(colorOf(tester, 'EW594'), AppColors.neutral400);
    expect(colorOf(tester, 'STR → PMI'), AppColors.neutral400);
    expect(colorOf(tester, 'landed ✓'), AppColors.neutral400);
  });

  testWidgets('marks a missed flight as missed', (tester) async {
    await pumpRow(tester, state: FlightState.missed);

    expect(find.text('missed'), findsOneWidget);
  });

  testWidgets(
    'leaves a past row without a subtitle when the route is unknown',
    (tester) async {
      await pumpRow(tester, state: FlightState.ended, row: flight(route: null));

      expect(find.text('EW594'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
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

    await pumpRow(
      tester,
      state: FlightState.waiting,
      row: flight(note: 'Anna & Ben ${'and everyone else ' * 10}'),
    );

    expect(tester.getSize(find.text('today')).width, accessoryWidth);
    expect(tester.getSize(find.byType(FlightRow)).width, _rowWidth);
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
      state: FlightState.planned,
      locale: const Locale('de'),
    );
    expect(find.text('STR → PMI · geplant'), findsOneWidget);
    expect(find.text('Sa., 15. Aug.'), findsOneWidget);

    await pumpRow(tester, state: FlightState.ended, locale: const Locale('de'));
    expect(find.text('gelandet ✓'), findsOneWidget);

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
