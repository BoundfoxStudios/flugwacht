import 'dart:async';

import 'package:flugwacht/data/lookup/route_lookup.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/data/persistence/flight_repository.dart';
import 'package:flugwacht/data/settings/notification_setting.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/new_flight_preview_card.dart';
import 'package:flugwacht/ui/screens/new_flight_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/controls/app_primary_button.dart';
import 'package:flugwacht/ui/widgets/controls/app_segmented_control.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

Future<FlightRepository> pumpNewFlightScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  TargetPlatform platform = TargetPlatform.android,
  RouteLookup? routeLookup,
  NotificationService? notificationService,
  NotificationSetting? notificationSetting,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = createTestRepository();
  final notifications = await createTestNotificationSetting();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold()),
      GoRoute(
        path: '/new-flight',
        builder: (context, state) => NewFlightScreen(
          flightRepository: repository,
          airlineDirectory: createTestAirlineDirectory(),
          routeLookup: routeLookup ?? FakeRouteLookup(),
          notificationService:
              notificationService ?? createTestNotificationService(),
          notificationSetting: notificationSetting ?? notifications,
          today: DateTime(2026, 8, 12),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme().copyWith(platform: platform),
      routerConfig: router,
    ),
  );
  unawaited(router.push('/new-flight'));
  await tester.pumpAndSettle();
  return repository;
}

Future<void> tapSegment(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppSegmentedControl<FlightLookupKind>),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enterLookupValue(WidgetTester tester, String value) async {
  await tester.enterText(find.byType(TextField).first, value);
  await tester.pumpAndSettle();
}

Future<void> settleRouteLookup(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> submit(WidgetTester tester) async {
  await tester.tap(find.byType(AppPrimaryButton));
  await tester.pumpAndSettle();
}

Future<Flight> savedFlight(
  WidgetTester tester,
  FlightRepository repository,
) async =>
    (await tester.runAsync(() => repository.watchFlights().first))!.single;

VoidCallback? submitCallback(WidgetTester tester) =>
    tester.widget<AppPrimaryButton>(find.byType(AppPrimaryButton)).onPressed;

Future<void> pickDepartureTime(
  WidgetTester tester, {
  required String hour,
  required String minute,
  String dayPeriod = 'PM',
}) async {
  await tester.tap(find.text('Not set'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), hour);
  await tester.enterText(fields.at(1), minute);
  await tester.tap(find.text(dayPeriod));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('swaps hint and validation with the selected segment', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    expect(find.text('As printed on your ticket, e.g. LH 400'), findsOneWidget);

    await tapSegment(tester, 'Registration');

    expect(
      find.text('The registration of the aircraft, e.g. D-AIMA'),
      findsOneWidget,
    );
    expect(find.text('As printed on your ticket, e.g. LH 400'), findsNothing);
  });

  testWidgets('keeps the value of every segment while switching', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);
    await enterLookupValue(tester, 'LH 400');

    await tapSegment(tester, 'Registration');
    await enterLookupValue(tester, 'D-AIMA');
    await tapSegment(tester, 'Flight number');

    expect(find.text('LH 400'), findsOneWidget);

    await tapSegment(tester, 'Registration');

    expect(find.text('D-AIMA'), findsOneWidget);
  });

  testWidgets('enables the button only for a parseable flight number', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'LH');

    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'LH 400');

    expect(submitCallback(tester), isNotNull);
  });

  testWidgets('enables the button only for a registration of allowed shape', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);
    await tapSegment(tester, 'Registration');

    await enterLookupValue(tester, 'D');
    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'D-AIMA');
    expect(submitCallback(tester), isNotNull);
  });

  testWidgets('enables the button only for six hex digits', (tester) async {
    await pumpNewFlightScreen(tester);
    await tapSegment(tester, 'Hex');

    await enterLookupValue(tester, '3C64');
    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'XYZXYZ');
    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, '3C6444');
    expect(submitCallback(tester), isNotNull);
  });

  testWidgets('shows the low cost carrier hint for their flight numbers only', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);
    final hint = find.textContaining('Ryanair, easyJet and Wizz Air');

    await enterLookupValue(tester, 'LH 400');
    expect(hint, findsNothing);

    await enterLookupValue(tester, 'FR 1234');
    expect(hint, findsOneWidget);

    await tapSegment(tester, 'Hex');
    expect(hint, findsNothing);
  });

  testWidgets('opens the material date picker within the allowed range', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await tester.tap(find.text('Wed, August 12, 2026'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(dialog.initialDate, DateTime(2026, 8, 12));
    expect(dialog.firstDate, DateTime(2026, 8, 11));
    expect(dialog.lastDate, DateTime(2027, 8, 12));
  });

  testWidgets('shows the picked date in the departure date field', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await tester.tap(find.text('Wed, August 12, 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Thu, August 20, 2026'), findsOneWidget);
  });

  testWidgets('opens the cupertino date picker on ios', (tester) async {
    await pumpNewFlightScreen(tester, platform: TargetPlatform.iOS);

    await tester.tap(find.text('Wed, August 12, 2026'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('offers the departure time as an empty optional field', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    expect(find.text('Departure time (optional)'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('shows the picked time in the departure time field', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await pickDepartureTime(tester, hour: '4', minute: '10');

    expect(find.text('4:10 PM'), findsOneWidget);
    expect(find.text('Not set'), findsNothing);
  });

  testWidgets('saves the picked departure time', (tester) async {
    final repository = await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await pickDepartureTime(tester, hour: '4', minute: '10');
    await submit(tester);

    final flight = await savedFlight(tester, repository);
    expect(flight.departureTime, const DayTime(16, 10));
  });

  testWidgets('saves no departure time while the field stays empty', (
    tester,
  ) async {
    final repository = await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);

    expect((await savedFlight(tester, repository)).departureTime, isNull);
  });

  testWidgets('clears a picked departure time again', (tester) async {
    final repository = await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await pickDepartureTime(tester, hour: '4', minute: '10');
    await tester.tap(find.byTooltip('Clear the departure time'));
    await tester.pumpAndSettle();
    expect(find.text('Not set'), findsOneWidget);

    await submit(tester);

    expect((await savedFlight(tester, repository)).departureTime, isNull);
  });

  testWidgets('opens the cupertino time picker on ios', (tester) async {
    await pumpNewFlightScreen(tester, platform: TargetPlatform.iOS);

    await tester.tap(find.text('Not set'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('renders the german copy for a german locale', (tester) async {
    await pumpNewFlightScreen(tester, locale: const Locale('de'));

    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Wie auf dem Ticket, z. B. LH 400'), findsOneWidget);
    expect(find.text('Mi, 12. August 2026'), findsOneWidget);
    expect(find.text('Abflugzeit (optional)'), findsOneWidget);
    expect(find.text('Keine Angabe'), findsOneWidget);
    expect(find.text('Flug eintragen'), findsOneWidget);
  });

  testWidgets('shows the found route with callsign and airline', (
    tester,
  ) async {
    await pumpNewFlightScreen(
      tester,
      routeLookup: FakeRouteLookup(const RouteFound('DLH400', _route)),
    );

    await enterLookupValue(tester, 'LH 400');
    await settleRouteLookup(tester);

    expect(find.text('Found'), findsOneWidget);
    expect(find.text('FRA → JFK'), findsOneWidget);
    expect(find.text('Callsign: DLH400'), findsOneWidget);
    expect(
      find.text('Frankfurt am Main → New York JFK · Lufthansa'),
      findsOneWidget,
    );
  });

  testWidgets('shows the route as unknown when no candidate has one', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await settleRouteLookup(tester);

    expect(find.text('Route unknown'), findsOneWidget);
  });

  testWidgets('shows no preview card for a registration', (tester) async {
    await pumpNewFlightScreen(
      tester,
      routeLookup: FakeRouteLookup(const RouteFound('DLH400', _route)),
    );
    await tapSegment(tester, 'Registration');

    await enterLookupValue(tester, 'D-AIMA');
    await settleRouteLookup(tester);

    expect(find.byType(NewFlightPreviewCard), findsNothing);
  });

  testWidgets('saves a flight number flight with its callsign and route', (
    tester,
  ) async {
    final repository = await pumpNewFlightScreen(
      tester,
      routeLookup: FakeRouteLookup(const RouteFound('DLH400', _route)),
    );

    await enterLookupValue(tester, 'lh 400');
    await settleRouteLookup(tester);
    await tester.enterText(find.byType(TextField).last, 'Anna & Ben');
    await submit(tester);

    final flight = await savedFlight(tester, repository);
    expect(flight.lookupKind, FlightLookupKind.flightNumber);
    expect(flight.lookupValue, 'LH400');
    expect(flight.departureDate, const CalendarDate(2026, 8, 12));
    expect(flight.note, 'Anna & Ben');
    expect(flight.expectedCallsign, 'DLH400');
    expect(flight.route?.origin.icaoCode, 'EDDF');
    expect(flight.route?.destination.icaoCode, 'KJFK');
  });

  testWidgets('saves without a route and falls back to the first candidate', (
    tester,
  ) async {
    final repository = await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);

    final flight = await savedFlight(tester, repository);
    expect(flight.route, isNull);
    expect(flight.expectedCallsign, 'DLH400');
    expect(flight.note, isNull);
  });

  testWidgets('saves a registration flight upper cased and without a route', (
    tester,
  ) async {
    final repository = await pumpNewFlightScreen(tester);
    await tapSegment(tester, 'Registration');

    await enterLookupValue(tester, 'd-aima');
    await submit(tester);

    final flight = await savedFlight(tester, repository);
    expect(flight.lookupKind, FlightLookupKind.registration);
    expect(flight.lookupValue, 'D-AIMA');
    expect(flight.expectedCallsign, isNull);
    expect(flight.route, isNull);
  });

  testWidgets('saves a hex flight lower cased', (tester) async {
    final repository = await pumpNewFlightScreen(tester);
    await tapSegment(tester, 'Hex');

    await enterLookupValue(tester, '3C6444');
    await submit(tester);

    final flight = await savedFlight(tester, repository);
    expect(flight.lookupKind, FlightLookupKind.hexAddress);
    expect(flight.lookupValue, '3c6444');
  });

  testWidgets('ignores a second tap while the flight is being saved', (
    tester,
  ) async {
    final repository = await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.tap(find.byType(AppPrimaryButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    final flights = await tester.runAsync(
      () => repository.watchFlights().first,
    );
    expect(flights, hasLength(1));
  });

  testWidgets('closes the modal once the notification offer is answered', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);
    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();

    expect(find.byType(NewFlightScreen), findsNothing);
  });

  testWidgets('offers the notifications when the first flight is saved', (
    tester,
  ) async {
    final service = createTestNotificationService();
    final setting = await createTestNotificationSetting();
    await pumpNewFlightScreen(
      tester,
      notificationService: service,
      notificationSetting: setting,
    );

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);

    expect(find.text('Turn notifications on?'), findsOneWidget);
    expect(service.permissionRequests, 0);
  });

  testWidgets('an accepted offer switches every kind on and asks the system', (
    tester,
  ) async {
    final service = createTestNotificationService();
    final setting = await createTestNotificationSetting();
    await pumpNewFlightScreen(
      tester,
      notificationService: service,
      notificationSetting: setting,
    );

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);
    await tester.tap(find.text('Yes, please'));
    await tester.pumpAndSettle();

    for (final kind in FlightNotification.values) {
      expect(setting.isEnabled(kind), isTrue, reason: kind.name);
    }
    expect(service.permissionRequests, 1);
  });

  testWidgets('a declined offer leaves everything off and asks for nothing', (
    tester,
  ) async {
    final service = createTestNotificationService();
    final setting = await createTestNotificationSetting();
    await pumpNewFlightScreen(
      tester,
      notificationService: service,
      notificationSetting: setting,
    );

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);
    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();

    for (final kind in FlightNotification.values) {
      expect(setting.isEnabled(kind), isFalse, reason: kind.name);
    }
    expect(service.permissionRequests, 0);
  });

  testWidgets('offers nothing a second time, whatever the answer was', (
    tester,
  ) async {
    final service = createTestNotificationService();
    final setting = await createTestNotificationSetting();
    await pumpNewFlightScreen(
      tester,
      notificationService: service,
      notificationSetting: setting,
    );
    await enterLookupValue(tester, 'LH 400');
    await submit(tester);
    await tester.tap(find.text('No thanks'));
    await tester.pumpAndSettle();

    await pumpNewFlightScreen(
      tester,
      notificationService: service,
      notificationSetting: setting,
    );
    await enterLookupValue(tester, 'LH 401');
    await submit(tester);

    expect(find.text('Turn notifications on?'), findsNothing);
  });

  testWidgets('offers nothing on a device that could not set up', (
    tester,
  ) async {
    final service = createTestNotificationService(
      permission: NotificationPermission.unavailable,
    );
    await pumpNewFlightScreen(tester, notificationService: service);

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);

    expect(find.text('Turn notifications on?'), findsNothing);
    expect(service.permissionRequests, 0);
  });

  testWidgets('offers nothing once the permission has been decided', (
    tester,
  ) async {
    final service = createTestNotificationService(
      permission: NotificationPermission.denied,
    );
    await pumpNewFlightScreen(tester, notificationService: service);

    await enterLookupValue(tester, 'LH 400');
    await submit(tester);

    expect(find.text('Turn notifications on?'), findsNothing);
    expect(service.permissionRequests, 0);
  });
}
