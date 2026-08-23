import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/map_selection.dart';
import 'package:flugwacht/ui/screens/list_empty_state.dart';
import 'package:flugwacht/ui/screens/list_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/chrome/app_fab.dart';
import 'package:flugwacht/ui/widgets/flight/flight_hero_cell.dart';
import 'package:flugwacht/ui/widgets/flight/flight_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/rendered_pixels.dart';
import '../../support/test_dependencies.dart';

const _screenKey = ValueKey('screen');

final _today = DateTime(2026, 8, 12, 9, 30);

Flight _flight({
  int id = 1,
  String lookupValue = 'LH400',
  String? note,
  CalendarDate date = const CalendarDate(2026, 8, 12),
  FlightTracking tracking = const FlightTracking(),
  bool liveActivityArmed = false,
}) => Flight(
  id: id,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: lookupValue,
  departureDate: date,
  note: note,
  tracking: tracking,
  liveActivityArmed: liveActivityArmed,
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
  MapSelection? selection,
  Locale locale = const Locale('en'),
  FakeLiveActivityService? liveActivityService,
}) async {
  final repository = FakeFlightRepository();
  addTearDown(repository.dispose);
  final mapSelection = selection ?? MapSelection();
  addTearDown(mapSelection.dispose);
  final mapStyleSetting = await createTestMapStyleSetting();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => ListScreen(
          flightRepository: repository,
          mapSelection: mapSelection,
          clock: () => _today,
          mapStyleSetting: mapStyleSetting,
          tileSources: testTileSources(),
          liveActivityService:
              liveActivityService ?? createTestLiveActivityService(),
        ),
      ),
      GoRoute(
        path: '/new-flight',
        builder: (context, state) =>
            const Scaffold(body: Text('new flight screen')),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const Scaffold(body: Text('map screen')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _screenKey,
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildLightTheme(),
        routerConfig: router,
      ),
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

  testWidgets('gives an airborne flight its hero cell and trail', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit([
      _flight(
        lookupValue: 'LH400',
        tracking: _seenAt(DateTime(2026, 8, 12, 9, 25)),
      ),
    ]);
    await tester.pump();

    expect(find.byType(FlightHeroCell), findsOneWidget);
    expect(find.byType(FlightRow), findsNothing);
    expect(repository.watchedTrails, [1]);
  });

  testWidgets('opens the tapped hero flight on the map', (tester) async {
    final selection = MapSelection();
    addTearDown(selection.dispose);
    final repository = await pumpListScreen(tester, selection: selection);
    repository.emit([
      _flight(id: 7, tracking: _seenAt(DateTime(2026, 8, 12, 9, 25))),
    ]);
    await tester.pump();

    await tester.tap(find.byType(FlightHeroCell));
    await tester.pumpAndSettle();

    expect(selection.flightId.value, 7);
    expect(find.text('map screen'), findsOneWidget);
  });

  testWidgets('leaves the rows of the other sections alone', (tester) async {
    final selection = MapSelection();
    addTearDown(selection.dispose);
    final repository = await pumpListScreen(tester, selection: selection);
    repository.emit([_flight(id: 7)]);
    await tester.pump();

    await tester.tap(find.byType(FlightRow));
    await tester.pumpAndSettle();

    expect(selection.flightId.value, isNull);
    expect(find.text('map screen'), findsNothing);
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
    expect(topOf('EW594'), lessThan(topOf('Past · gone in 24 h')));
    expect(topOf('Past · gone in 24 h'), lessThan(topOf('BA915')));
  });

  testWidgets('leaves out the past label while nothing is over', (
    tester,
  ) async {
    final repository = await pumpListScreen(tester);

    repository.emit([_flight()]);
    await tester.pump();

    expect(find.text('Past · gone in 24 h'), findsNothing);
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

  group('the live activity switch', () {
    const label = 'Live Activity on flight day';

    testWidgets('arms a flight from its row', (tester) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight(id: 7)]);
      await tester.pump();

      await tester.tap(find.text(label));
      await tester.pump();

      expect(repository.liveActivityArmings, [(7, true)]);
    });

    testWidgets('disarms a flight from its hero cell', (tester) async {
      final repository = await pumpListScreen(tester);
      repository.emit([
        _flight(
          id: 7,
          tracking: _seenAt(DateTime(2026, 8, 12, 9, 25)),
          liveActivityArmed: true,
        ),
      ]);
      await tester.pump();

      await tester.tap(find.text(label));
      await tester.pump();

      expect(repository.liveActivityArmings, [(7, false)]);
    });

    testWidgets('leaves the hero flight on the list while it is toggled', (
      tester,
    ) async {
      final selection = MapSelection();
      addTearDown(selection.dispose);
      final repository = await pumpListScreen(tester, selection: selection);
      repository.emit([
        _flight(id: 7, tracking: _seenAt(DateTime(2026, 8, 12, 9, 25))),
      ]);
      await tester.pump();

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(selection.flightId.value, isNull);
      expect(find.text('map screen'), findsNothing);
    });

    testWidgets('stays away from a flight that is over', (tester) async {
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

      expect(find.text(label), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(label)).dy,
        lessThan(tester.getTopLeft(find.text('BA915')).dy),
      );
    });

    testWidgets('takes no room where the device shows no activities', (
      tester,
    ) async {
      final liveActivityService = createTestLiveActivityService();
      liveActivityService.availability.value =
          LiveActivityAvailability.unsupported;
      final repository = await pumpListScreen(
        tester,
        liveActivityService: liveActivityService,
      );
      repository.emit([_flight()]);
      await tester.pump();
      final plainHeight = tester.getSize(find.byType(FlightRow)).height;

      liveActivityService.availability.value = LiveActivityAvailability.enabled;
      await tester.pump();

      expect(find.text(label), findsOneWidget);
      expect(
        tester.getSize(find.byType(FlightRow)).height,
        greaterThan(plainHeight),
      );
    });

    testWidgets('says why it does nothing where the system switched it off', (
      tester,
    ) async {
      final liveActivityService = createTestLiveActivityService();
      liveActivityService.availability.value =
          LiveActivityAvailability.disabled;
      final repository = await pumpListScreen(
        tester,
        liveActivityService: liveActivityService,
      );

      repository.emit([_flight()]);
      await tester.pump();

      expect(
        find.text(
          'Live Activities are switched off for Flugwacht in the system '
          'settings',
        ),
        findsOneWidget,
      );
    });
  });

  group('deleting a flight', () {
    Future<void> swipeAway(WidgetTester tester, Finder target) async {
      await tester.drag(target, const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    /// Ends the undo window the way a timeout would, without waiting one out.
    Future<void> dismissSnackBar(WidgetTester tester) async {
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
    }

    testWidgets('a swiped row leaves the list and offers an undo', (
      tester,
    ) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight()]);
      await tester.pump();

      await swipeAway(tester, find.byType(FlightRow));

      expect(find.byType(FlightRow), findsNothing);
      expect(find.text('LH400 deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(repository.deletedFlightIds, isEmpty);
    });

    testWidgets('undo brings the row back and deletes nothing', (tester) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight()]);
      await tester.pump();
      await swipeAway(tester, find.byType(FlightRow));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.byType(FlightRow), findsOneWidget);
      expect(repository.deletedFlightIds, isEmpty);
    });

    testWidgets('the delete lands once the undo is gone', (tester) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight(id: 7)]);
      await tester.pump();
      await swipeAway(tester, find.byType(FlightRow));

      await dismissSnackBar(tester);
      repository.emit(const []);
      await tester.pumpAndSettle();

      expect(repository.deletedFlightIds, [7]);
      expect(find.byType(FlightRow), findsNothing);
    });

    testWidgets('commits the delete when the undo snackbar times out', (
      tester,
    ) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight(id: 7)]);
      await tester.pump();
      await swipeAway(tester, find.byType(FlightRow));

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('LH400 deleted'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('LH400 deleted'), findsNothing);
      expect(repository.deletedFlightIds, [7]);
    });

    testWidgets('keeps the delete panel flush with the swiped card', (
      tester,
    ) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight()]);
      await tester.pump();

      final row = tester.getRect(find.byType(FlightRow));
      final gesture = await tester.startGesture(row.center);
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      final pixels = await renderedPixels(tester, _screenKey);
      final behindCardEdge = Offset(row.right - 100 + 4, row.center.dy);
      expect(
        pixels.matches(behindCardEdge, AppColors.destructiveLight),
        isTrue,
        reason: 'the delete panel must meet the card edge without a gap',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the delete panel reaches under the rounded card corners', (
      tester,
    ) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight()]);
      await tester.pump();

      final row = tester.getRect(find.byType(FlightRow));
      final gesture = await tester.startGesture(row.center);
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      final pixels = await renderedPixels(tester, _screenKey);
      final cornerCutout = Offset(row.right - 100 - 1, row.top + 1);
      expect(
        pixels.matches(cornerCutout, AppColors.destructiveLight),
        isTrue,
        reason:
            'the card corner must be cut out of the panel, not the panel '
            'out of the scaffold',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the hero cell is swiped away the same way', (tester) async {
      final repository = await pumpListScreen(tester);
      repository.emit([_flight(id: 3, tracking: _seenAt(_today))]);
      await tester.pump();

      await swipeAway(tester, find.byType(FlightHeroCell));

      expect(find.byType(FlightHeroCell), findsNothing);
      expect(find.text('Undo'), findsOneWidget);

      await dismissSnackBar(tester);

      expect(repository.deletedFlightIds, [3]);
    });
  });
}
