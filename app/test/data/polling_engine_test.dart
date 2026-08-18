import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flugwacht/data/adapters/lookup_result.dart';
import 'package:flugwacht/data/adapters/readsb_source_adapter.dart';
import 'package:flugwacht/data/notifications/flight_notifier.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/data/polling_engine.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/test_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const departureDate = CalendarDate(2026, 3, 17);
  final window = FlightDayWindow.forDepartureDate(departureDate);
  final noon = window.start.add(const Duration(hours: 12));

  Flight flightWith({
    int id = 1,
    FlightLookupKind lookupKind = FlightLookupKind.flightNumber,
    String lookupValue = 'LH400',
    DayTime? departureTime,
    String? hexAddress,
    String? expectedCallsign,
    FixPosition? latestPosition,
  }) => Flight(
    id: id,
    lookupKind: lookupKind,
    lookupValue: lookupValue,
    departureDate: departureDate,
    departureTime: departureTime,
    hexAddress: hexAddress,
    expectedCallsign: expectedCallsign,
    tracking: FlightTracking(latestPosition: latestPosition),
  );

  FixPosition positionAt(DateTime timestamp) => FixPosition(
    latitude: 49.875687,
    longitude: 7.888834,
    timestamp: timestamp,
    onGround: false,
  );

  Fix fixWith({
    String hexAddress = '3c64c6',
    String? callsign,
    DateTime? positionAtTimestamp,
  }) => Fix(
    hexAddress: hexAddress,
    sourceId: SourceId.adsblol,
    callsign: callsign,
    position: positionAtTimestamp == null
        ? null
        : positionAt(positionAtTimestamp),
  );

  LookupResult successWith(Fix fix) => LookupSuccess([fix]);

  FlightNotifier notifierFor(
    FakeAsync async,
    FakeFlightRepository repository,
    NotificationService service,
  ) => FlightNotifier(
    repository: repository,
    service: service,
    setting: FakeNotificationSetting(),
    copy: (kind, flight) => (title: flight.lookupValue, body: kind.name),
    clock: () => noon.add(async.elapsed),
  );

  ({
    PollingEngine engine,
    FakeFlightRepository repository,
    FakeSourceAdapter adapter,
    FakeNotificationService notifications,
  })
  startEngine(
    FakeAsync async,
    List<Flight> flights, {
    FakeFlightRepository? withRepository,
  }) {
    final repository = withRepository ?? FakeFlightRepository();
    final adapter = FakeSourceAdapter();
    final notifications = createTestNotificationService();
    final engine = PollingEngine(
      repository: repository,
      adapters: {SourceId.adsblol: adapter},
      activeSourceId: () => SourceId.adsblol,
      airlineDirectory: createTestAirlineDirectory(),
      notifier: notifierFor(async, repository, notifications),
      clock: () => noon.add(async.elapsed),
    )..start();
    repository.emit(flights);
    return (
      engine: engine,
      repository: repository,
      adapter: adapter,
      notifications: notifications,
    );
  }

  test('searches the callsign candidates in order until one answers', () {
    fakeAsync((async) {
      final started = startEngine(async, [flightWith()]);
      started.adapter.results['GEC400'] = successWith(
        fixWith(callsign: 'GEC400', positionAtTimestamp: noon),
      );

      async.flushMicrotasks();

      expect(started.adapter.callsignRequests, ['DLH400', 'GEC400']);
      final (flightId, tracking) = started.repository.trackingUpdates.single;
      expect(flightId, 1);
      expect(tracking.latestPosition?.timestamp, noon);
      expect(started.repository.trailAppends.single.$2.timestamp, noon);
      expect(started.repository.trailAppends.single.$3, SourceId.adsblol);
      expect(started.repository.identityUpdates.single, (
        1,
        '3c64c6',
        'GEC400',
      ));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('stops the candidate chain at the first hit', () {
    fakeAsync((async) {
      final started = startEngine(async, [flightWith()]);
      started.adapter.results['DLH400'] = successWith(
        fixWith(callsign: 'DLH400', positionAtTimestamp: noon),
      );

      async.flushMicrotasks();

      expect(started.adapter.callsignRequests, ['DLH400']);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('polls a live flight every five seconds', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.flushMicrotasks();
      expect(started.adapter.hexAddressRequests, hasLength(1));

      async.elapse(const Duration(seconds: 4, milliseconds: 999));
      expect(started.adapter.hexAddressRequests, hasLength(1));

      async.elapse(const Duration(milliseconds: 1));
      expect(started.adapter.hexAddressRequests, hasLength(2));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('polls a waiting flight once a minute', () {
    fakeAsync((async) {
      final started = startEngine(async, [flightWith()]);
      async.flushMicrotasks();
      expect(started.adapter.callsignRequests, hasLength(2));

      async.elapse(const Duration(seconds: 59));
      expect(started.adapter.callsignRequests, hasLength(2));

      async.elapse(const Duration(seconds: 1));
      expect(started.adapter.callsignRequests, hasLength(4));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('polls a flight without a signal once a minute', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(
            noon.subtract(const Duration(minutes: 30)),
          ),
        ),
      ]);
      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 59));
      expect(started.adapter.hexAddressRequests, hasLength(1));

      async.elapse(const Duration(seconds: 1));
      expect(started.adapter.hexAddressRequests, hasLength(2));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('returns to the five second cadence once a fix comes back', () {
    fakeAsync((async) {
      final staleFlight = flightWith(
        hexAddress: '3c64c6',
        expectedCallsign: 'DLH400',
        latestPosition: positionAt(noon.subtract(const Duration(minutes: 30))),
      );
      final started = startEngine(async, [staleFlight]);
      async.flushMicrotasks();

      started.repository.emit([
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.elapse(const Duration(seconds: 5));

      expect(started.adapter.hexAddressRequests, hasLength(2));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('clears the hex address when the airframe flies another callsign', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      started.adapter.results['3c64c6'] = successWith(
        fixWith(callsign: 'DLH8', positionAtTimestamp: noon),
      );

      async.flushMicrotasks();

      expect(started.repository.identityUpdates.single, (1, null, 'DLH400'));
      expect(started.repository.trackingUpdates, isEmpty);
      expect(started.repository.trailAppends, isEmpty);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('searches by callsign again after a rejected identity', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.flushMicrotasks();

      started.repository.emit([
        flightWith(
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.elapse(const Duration(seconds: 5));

      expect(started.adapter.callsignRequests, ['DLH400', 'GEC400']);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('writes nothing and retries after an empty result', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);

      async.elapse(const Duration(seconds: 5));

      expect(started.adapter.hexAddressRequests, hasLength(2));
      expect(started.repository.trackingUpdates, isEmpty);
      expect(started.repository.trailAppends, isEmpty);
      expect(started.repository.identityUpdates, isEmpty);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  for (final failure in const <LookupResult>[
    LookupNetworkFailure(),
    LookupStatusFailure(503),
    LookupMalformedPayload(),
  ]) {
    test('writes nothing and retries after a ${failure.runtimeType}', () {
      fakeAsync((async) {
        final started = startEngine(async, [
          flightWith(
            hexAddress: '3c64c6',
            expectedCallsign: 'DLH400',
            latestPosition: positionAt(noon),
          ),
        ]);
        started.adapter.results['3c64c6'] = failure;

        async.elapse(const Duration(seconds: 5));

        expect(started.adapter.hexAddressRequests, hasLength(2));
        expect(started.repository.trackingUpdates, isEmpty);
        expect(started.repository.identityUpdates, isEmpty);

        started.engine.stop();
        started.repository.dispose();
      });
    });
  }

  test('never runs two lookups for the same flight at once', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      started.adapter.pendingResult = Completer<LookupResult>();

      async.elapse(const Duration(seconds: 20));

      expect(started.adapter.hexAddressRequests, hasLength(1));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('keeps polling the other flights while one lookup hangs', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
        flightWith(
          id: 2,
          lookupKind: FlightLookupKind.registration,
          lookupValue: 'D-AIXP',
          latestPosition: positionAt(noon),
        ),
      ]);
      started.adapter.pendingResult = Completer<LookupResult>();

      async.elapse(const Duration(seconds: 5));

      expect(started.adapter.hexAddressRequests, hasLength(1));
      expect(started.adapter.registrationRequests, hasLength(1));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('pauses in the background and checks again on resume', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.flushMicrotasks();
      expect(started.adapter.hexAddressRequests, hasLength(1));

      started.engine.didChangeAppLifecycleState(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 30));
      expect(started.adapter.hexAddressRequests, hasLength(1));

      started.engine.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(started.adapter.hexAddressRequests, hasLength(2));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('issues no further candidate request once it is backgrounded', () {
    fakeAsync((async) {
      final started = startEngine(async, [flightWith()]);
      started.adapter.pendingResult = Completer<LookupResult>();
      async.flushMicrotasks();
      expect(started.adapter.callsignRequests, ['DLH400']);

      started.engine.didChangeAppLifecycleState(AppLifecycleState.paused);
      started.adapter.pendingResult!.complete(const LookupSuccess([]));
      async.elapse(const Duration(seconds: 5));

      expect(started.adapter.callsignRequests, ['DLH400']);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('writes nothing that arrives after it was stopped', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      started.adapter
        ..pendingResult = Completer<LookupResult>()
        ..results['3c64c6'] = successWith(
          fixWith(callsign: 'DLH400', positionAtTimestamp: noon),
        );
      async.flushMicrotasks();

      started.engine.stop();
      started.adapter.pendingResult!.complete(
        started.adapter.results['3c64c6'],
      );
      async.elapse(const Duration(seconds: 5));

      expect(started.repository.trackingUpdates, isEmpty);
      expect(started.repository.trailAppends, isEmpty);

      started.repository.dispose();
    });
  });

  test('polls a flight that is added while it runs', () {
    fakeAsync((async) {
      final started = startEngine(async, const []);
      async.elapse(const Duration(seconds: 10));
      expect(started.adapter.callsignRequests, isEmpty);

      started.repository.emit([flightWith()]);
      async.flushMicrotasks();

      expect(started.adapter.callsignRequests, hasLength(2));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('stops polling a flight that has landed', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.flushMicrotasks();

      started.repository.emit([
        Flight(
          id: 1,
          lookupKind: FlightLookupKind.flightNumber,
          lookupValue: 'LH400',
          departureDate: departureDate,
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          tracking: FlightTracking(
            latestPosition: FixPosition(
              latitude: 49.875687,
              longitude: 7.888834,
              timestamp: noon,
              onGround: true,
            ),
            hasBeenAirborne: true,
            lastKnownOnGround: true,
          ),
        ),
      ]);
      async.elapse(const Duration(minutes: 5));

      expect(started.adapter.hexAddressRequests, hasLength(1));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('queries a registration flight by its registration only', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          lookupKind: FlightLookupKind.registration,
          lookupValue: 'D-AIXP',
        ),
      ]);
      started.adapter.results['D-AIXP'] = successWith(
        fixWith(callsign: 'DLH8', positionAtTimestamp: noon),
      );

      async.flushMicrotasks();

      expect(started.adapter.registrationRequests, ['D-AIXP']);
      expect(started.adapter.callsignRequests, isEmpty);
      expect(started.repository.trackingUpdates, hasLength(1));
      expect(started.repository.identityUpdates, isEmpty);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('queries an entered hex address without adopting an identity', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          lookupKind: FlightLookupKind.hexAddress,
          lookupValue: '3c64c6',
        ),
      ]);
      started.adapter.results['3c64c6'] = successWith(
        fixWith(callsign: 'DLH8', positionAtTimestamp: noon),
      );

      async.flushMicrotasks();

      expect(started.adapter.hexAddressRequests, ['3c64c6']);
      expect(started.repository.trackingUpdates, hasLength(1));
      expect(started.repository.identityUpdates, isEmpty);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  group('acquisition anchor', () {
    test('waits for the scheduled departure before the first search', () {
      fakeAsync((async) {
        final started = startEngine(async, [
          flightWith(departureTime: const DayTime(15, 0)),
        ]);

        async.elapse(const Duration(minutes: 59, seconds: 59));
        expect(started.adapter.callsignRequests, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(started.adapter.callsignRequests, hasLength(2));

        started.engine.stop();
        started.repository.dispose();
      });
    });

    test('searches from the window start without a scheduled departure', () {
      fakeAsync((async) {
        final started = startEngine(async, [flightWith()]);
        async.flushMicrotasks();

        expect(started.adapter.callsignRequests, hasLength(2));

        started.engine.stop();
        started.repository.dispose();
      });
    });

    test('ignores the anchor once the flight has been found', () {
      fakeAsync((async) {
        final started = startEngine(async, [
          flightWith(
            departureTime: const DayTime(16, 10),
            hexAddress: '3c64c6',
            expectedCallsign: 'DLH400',
          ),
        ]);
        async.flushMicrotasks();

        expect(started.adapter.hexAddressRequests, hasLength(1));

        started.engine.stop();
        started.repository.dispose();
      });
    });

    test('ignores the anchor for an airframe that was already seen', () {
      fakeAsync((async) {
        final started = startEngine(async, [
          flightWith(
            lookupKind: FlightLookupKind.registration,
            lookupValue: 'D-AIXP',
            departureTime: const DayTime(16, 10),
            latestPosition: positionAt(noon),
          ),
        ]);
        async.flushMicrotasks();

        expect(started.adapter.registrationRequests, hasLength(1));

        started.engine.stop();
        started.repository.dispose();
      });
    });
  });

  group('active source', () {
    ({PollingEngine engine, FakeFlightRepository repository}) startEngineOn(
      FakeAsync async,
      SourceId Function() activeSourceId,
      List<String> requestedUrls, {
      List<Flight> flights = const [],
    }) {
      final client = MockClient((request) async {
        requestedUrls.add(request.url.toString());
        return http.Response(
          '{"ac": [{"hex": "3c64c6", "flight": "DLH400", "lat": 49.875687, '
          '"lon": 7.888834, "seen_pos": 1}], '
          '"now": ${noon.add(async.elapsed).millisecondsSinceEpoch}}',
          200,
        );
      });
      final repository = FakeFlightRepository();
      final engine = PollingEngine(
        repository: repository,
        adapters: {
          for (final sourceId in SourceId.values)
            sourceId: ReadsbSourceAdapter(sourceId: sourceId, client: client),
        },
        activeSourceId: activeSourceId,
        airlineDirectory: createTestAirlineDirectory(),
        notifier: notifierFor(
          async,
          repository,
          createTestNotificationService(),
        ),
        clock: () => noon.add(async.elapsed),
      )..start();
      repository.emit(flights);
      return (engine: engine, repository: repository);
    }

    test('polls through the adapter of the source that is active', () {
      fakeAsync((async) {
        final requestedUrls = <String>[];
        var activeSourceId = SourceId.adsblol;
        final started = startEngineOn(
          async,
          () => activeSourceId,
          requestedUrls,
          flights: [
            flightWith(
              hexAddress: '3c64c6',
              expectedCallsign: 'DLH400',
              latestPosition: positionAt(noon),
            ),
          ],
        );
        async.flushMicrotasks();
        expect(requestedUrls.single, 'https://api.adsb.lol/v2/hex/3c64c6');

        activeSourceId = SourceId.adsbfi;
        async.elapse(const Duration(seconds: 5));

        expect(
          requestedUrls.last,
          'https://opendata.adsb.fi/api/v2/hex/3c64c6',
        );
        expect(started.repository.trailAppends.last.$3, SourceId.adsbfi);

        started.engine.stop();
        started.repository.dispose();
      });
    });

    test('keeps one adapter per source, so its rate limit spans flights', () {
      fakeAsync((async) {
        final requestedUrls = <String>[];
        final started = startEngineOn(
          async,
          () => SourceId.adsblol,
          requestedUrls,
          flights: [
            flightWith(
              hexAddress: '3c64c6',
              expectedCallsign: 'DLH400',
              latestPosition: positionAt(noon),
            ),
            flightWith(
              id: 2,
              lookupKind: FlightLookupKind.hexAddress,
              lookupValue: '3c64c7',
              latestPosition: positionAt(noon),
            ),
          ],
        );

        async.flushMicrotasks();
        expect(requestedUrls, hasLength(1));

        async.elapse(const Duration(seconds: 1));
        expect(requestedUrls, hasLength(2));

        started.engine.stop();
        started.repository.dispose();
      });
    });
  });

  test('stops every request once it is stopped', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(
          hexAddress: '3c64c6',
          expectedCallsign: 'DLH400',
          latestPosition: positionAt(noon),
        ),
      ]);
      async.flushMicrotasks();

      started.engine.stop();
      async.elapse(const Duration(minutes: 5));

      expect(started.adapter.hexAddressRequests, hasLength(1));

      started.repository.dispose();
    });
  });

  test('notifies once when a waiting flight turns up airborne', () {
    fakeAsync((async) {
      final started = startEngine(async, [
        flightWith(hexAddress: '3c64c6', expectedCallsign: 'DLH400'),
      ]);
      started.adapter.results['3c64c6'] = successWith(
        fixWith(callsign: 'DLH400', positionAtTimestamp: noon),
      );

      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 30));

      expect(started.notifications.shown, [(FlightNotification.departed, 1)]);
      expect(started.repository.notificationMarks, [
        (1, FlightNotification.departed),
      ]);

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('polls only once the delivered reminders are on record', () {
    fakeAsync((async) {
      final repository = FakeFlightRepository()
        ..pendingReconcile = Completer<void>();
      final started = startEngine(async, [
        flightWith(hexAddress: '3c64c6', expectedCallsign: 'DLH400'),
      ], withRepository: repository);

      async
        ..flushMicrotasks()
        ..elapse(const Duration(seconds: 30));
      expect(started.adapter.hexAddressRequests, isEmpty);

      repository.pendingReconcile!.complete();
      async.flushMicrotasks();

      expect(started.adapter.hexAddressRequests, hasLength(1));

      started.engine.stop();
      started.repository.dispose();
    });
  });

  test('takes the arrival reminder of a deleted flight back', () {
    fakeAsync((async) {
      final started = startEngine(async, [flightWith()]);
      async.flushMicrotasks();

      started.repository.emit(const []);
      async.flushMicrotasks();

      expect(started.notifications.cancelled, [
        (FlightNotification.arrivingSoon, 1),
      ]);

      started.engine.stop();
      started.repository.dispose();
    });
  });
}
