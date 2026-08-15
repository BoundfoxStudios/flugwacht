import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/l10n/app_localizations.dart';
import 'package:flugwacht/ui/screens/list_empty_state.dart';
import 'package:flugwacht/ui/screens/list_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/app_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/test_dependencies.dart';

final _today = DateTime(2026, 8, 12, 9, 30);

Flight _flight({
  int id = 1,
  String lookupValue = 'LH400',
  String? note,
  CalendarDate date = const CalendarDate(2026, 8, 12),
  FlightTracking tracking = const FlightTracking(),
}) => Flight(
  id: id,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: lookupValue,
  departureDate: date,
  note: note,
  tracking: tracking,
);

FlightTracking _seenAt(DateTime timestamp, {bool? onGround}) => FlightTracking(
  latestPosition: FixPosition(
    latitude: 50.026402,
    longitude: 8.543130,
    timestamp: timestamp,
  ),
  hasBeenAirborne: true,
  lastKnownOnGround: onGround,
);

Future<FakeFlightRepository> pumpListScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  final repository = FakeFlightRepository();
  addTearDown(repository.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            ListScreen(flightRepository: repository, clock: () => _today),
      ),
      GoRoute(
        path: '/new-flight',
        builder: (context, state) =>
            const Scaffold(body: Text('new flight screen')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      routerConfig: router,
    ),
  );
  return repository;
}

void main() {
  testWidgets('shows nothing until the repository has emitted', (tester) async {
    await pumpListScreen(tester);

    expect(find.text('Flights'), findsNothing);
    expect(find.byType(AppFab), findsNothing);
  });

  testWidgets('hands the whole screen to the empty state without a flight', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit(const []);
    await tester.pump();

    expect(find.byType(ListEmptyState), findsOneWidget);
    expect(find.byType(AppFab), findsNothing);
    expect(find.text('Flights'), findsNothing);
  });

  testWidgets('opens the new flight screen from the empty state', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);
    repository.emit(const []);
    await tester.pump();

    await tester.tap(find.text('Add flight'));
    await tester.pumpAndSettle();

    expect(find.text('new flight screen'), findsOneWidget);
  });

  testWidgets('heads the list with the title and today in English', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit([_flight()]);
    await tester.pump();

    expect(find.text('Flights'), findsOneWidget);
    expect(find.text('Wed, August 12'), findsOneWidget);
  });

  testWidgets('heads the list with the title and today in German', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester, locale: const Locale('de'));

    repository.emit([_flight()]);
    await tester.pump();

    expect(find.text('Flüge'), findsOneWidget);
    expect(find.text('Mi, 12. August'), findsOneWidget);
  });

  testWidgets('appends the note to the lookup value only when there is one', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit([
      _flight(note: 'Anna & Ben'),
      _flight(id: 2, lookupValue: 'EW594'),
    ]);
    await tester.pump();

    expect(find.text('LH400 · Anna & Ben'), findsOneWidget);
    expect(find.text('EW594'), findsOneWidget);
  });

  testWidgets('orders the sections active, waiting, planned, past', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit([
      _flight(id: 1, lookupValue: 'EW594'),
      _flight(
        id: 2,
        lookupValue: 'UA961',
        date: const CalendarDate(2026, 8, 20),
      ),
      _flight(
        id: 3,
        lookupValue: 'BA915',
        tracking: _seenAt(DateTime(2026, 8, 12, 8), onGround: true),
      ),
      _flight(
        id: 4,
        lookupValue: 'LH400',
        tracking: _seenAt(DateTime(2026, 8, 12, 9, 25)),
      ),
    ]);
    await tester.pump();

    double topOf(String title) => tester.getTopLeft(find.text(title)).dy;
    expect(topOf('LH400'), lessThan(topOf('EW594')));
    expect(topOf('EW594'), lessThan(topOf('UA961')));
    expect(topOf('UA961'), lessThan(topOf('BA915')));
  });

  testWidgets('labels the past section above its rows', (tester) async {
    final repository = await pumpListScreen(tester);

    repository.emit([
      _flight(id: 1, lookupValue: 'EW594'),
      _flight(
        id: 2,
        lookupValue: 'BA915',
        tracking: _seenAt(DateTime(2026, 8, 12, 8), onGround: true),
      ),
    ]);
    await tester.pump();

    double topOf(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(topOf('EW594'), lessThan(topOf('Past')));
    expect(topOf('Past'), lessThan(topOf('BA915')));
  });

  testWidgets('leaves out the past label while nothing is over', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit([_flight()]);
    await tester.pump();

    expect(find.text('Past'), findsNothing);
  });

  testWidgets('opens the new flight screen from the add button', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);
    repository.emit([_flight()]);
    await tester.pump();

    await tester.tap(find.byType(AppFab));
    await tester.pumpAndSettle();

    expect(find.text('new flight screen'), findsOneWidget);
  });
}
