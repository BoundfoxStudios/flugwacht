import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flugwacht/data/persistence/database.dart';
import 'package:flugwacht/data/persistence/flight_repository.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late FlightRepository repository;

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = FlightRepository(database);
  });

  tearDown(() => database.close());

  Future<Flight> addFlight({
    CalendarDate departureDate = const CalendarDate(2026, 3, 17),
    String? note,
  }) => repository.addFlight(
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH433',
    departureDate: departureDate,
    note: note,
  );

  final window = FlightDayWindow.forDepartureDate(
    const CalendarDate(2026, 3, 17),
  );

  FixPosition position(DateTime timestamp, {bool? onGround}) => FixPosition(
    latitude: 49.875687,
    longitude: 7.888834,
    timestamp: timestamp,
    barometricAltitudeFeet: 34000,
    onGround: onGround,
    geometricAltitudeFeet: 34500,
    trackDegrees: 271.4,
    trueHeadingDegrees: 269.8,
    groundSpeedKnots: 451.2,
    indicatedAirspeedKnots: 289.5,
    mach: 0.784,
    verticalRateFeetPerMinute: -640,
  );

  test('stores a flight with every field and returns it with its id', () async {
    final stored = await repository.addFlight(
      lookupKind: FlightLookupKind.registration,
      lookupValue: 'D-AIFF',
      departureDate: const CalendarDate(2026, 3, 17),
      note: 'Window seat',
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH433',
    );

    expect(stored.id, isPositive);
    expect(stored.tracking.latestPosition, isNull);
    expect(stored.tracking.hasBeenAirborne, isFalse);
    expect(stored.tracking.lastKnownOnGround, isNull);

    final reread = (await repository.watchFlights().first).single;
    expect(reread.id, stored.id);
    expect(reread.lookupKind, FlightLookupKind.registration);
    expect(reread.lookupValue, 'D-AIFF');
    expect(reread.departureDate, const CalendarDate(2026, 3, 17));
    expect(reread.note, 'Window seat');
    expect(reread.hexAddress, '3c64c6');
    expect(reread.expectedCallsign, 'DLH433');
  });

  test('leaves the optional fields empty when they are not given', () async {
    await addFlight();

    final stored = (await repository.watchFlights().first).single;
    expect(stored.note, isNull);
    expect(stored.hexAddress, isNull);
    expect(stored.expectedCallsign, isNull);
  });

  test('round-trips a departure date that needs zero padding', () async {
    await addFlight(departureDate: const CalendarDate(2026, 1, 5));

    final stored = (await repository.watchFlights().first).single;
    expect(stored.departureDate, const CalendarDate(2026, 1, 5));
  });

  group('scheduled departure time', () {
    Future<Flight> addFlightAt(DayTime? departureTime) => repository.addFlight(
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH433',
      departureDate: const CalendarDate(2026, 3, 17),
      departureTime: departureTime,
    );

    test('round-trips a scheduled departure time', () async {
      await addFlightAt(const DayTime(16, 10));

      final stored = (await repository.watchFlights().first).single;
      expect(stored.departureTime, const DayTime(16, 10));
    });

    test('round-trips a departure time at midnight', () async {
      await addFlightAt(const DayTime(0, 0));

      final stored = (await repository.watchFlights().first).single;
      expect(stored.departureTime, const DayTime(0, 0));
    });

    test('reads back no time for a flight added without one', () async {
      await addFlightAt(null);

      final stored = (await repository.watchFlights().first).single;
      expect(stored.departureTime, isNull);
    });

    test('round-trips an origin-local departure interpretation', () async {
      await repository.addFlight(
        lookupKind: FlightLookupKind.flightNumber,
        lookupValue: 'LH433',
        departureDate: const CalendarDate(2026, 3, 17),
        departureTime: const DayTime(16, 10),
        departureTimeInterpretation: DepartureTimeInterpretation.originLocal,
      );

      final stored = (await repository.watchFlights().first).single;
      expect(
        stored.departureTimeInterpretation,
        DepartureTimeInterpretation.originLocal,
      );
    });

    test('stores a flight without an interpretation as device time', () async {
      await addFlightAt(const DayTime(16, 10));

      final stored = (await repository.watchFlights().first).single;
      expect(
        stored.departureTimeInterpretation,
        DepartureTimeInterpretation.device,
      );
    });
  });

  group('notification markers', () {
    test('remembers when a notification went out', () async {
      final flight = await addFlight();
      final deliveredAt = DateTime.utc(2026, 3, 17, 14, 30);

      await repository.claimNotification(
        flight.id,
        FlightNotification.departed,
        deliveredAt,
      );

      final stored = (await repository.watchFlights().first).single;
      expect(stored.notifications.departedAt, deliveredAt);
      expect(stored.notifications.arrivingSoonAt, isNull);
      expect(stored.notifications.landedAt, isNull);
    });

    test('keeps the markers of the other notifications', () async {
      final flight = await addFlight();

      for (final kind in FlightNotification.values) {
        await repository.claimNotification(
          flight.id,
          kind,
          DateTime.utc(2026, 3, 17, 14, 30),
        );
      }

      final stored = (await repository.watchFlights().first).single;
      for (final kind in FlightNotification.values) {
        expect(
          stored.notifications.isDelivered(kind),
          isTrue,
          reason: kind.name,
        );
      }
    });

    test('starts a new flight without any marker', () async {
      final flight = await addFlight();

      expect(flight.notifications.departedAt, isNull);
      expect(flight.notifications.arrivingSoonAt, isNull);
      expect(flight.notifications.landedAt, isNull);
      expect(flight.notifications.arrivingSoonScheduledFor, isNull);
    });

    test('grants a notification to the first claim only', () async {
      final flight = await addFlight();
      final deliveredAt = DateTime.utc(2026, 3, 17, 14, 30);

      final first = await repository.claimNotification(
        flight.id,
        FlightNotification.departed,
        deliveredAt,
      );
      final second = await repository.claimNotification(
        flight.id,
        FlightNotification.departed,
        deliveredAt.add(const Duration(minutes: 5)),
      );

      expect(first, isTrue);
      expect(second, isFalse);
      final stored = (await repository.watchFlights().first).single;
      expect(stored.notifications.departedAt, deliveredAt);
    });

    test('leaves the flights it was not asked about alone', () async {
      final flight = await addFlight();
      final other = await addFlight();

      await repository.claimNotification(
        flight.id,
        FlightNotification.departed,
        DateTime.utc(2026, 3, 17, 14, 30),
      );

      final stored = await repository.watchFlights().first;
      final untouched = stored.firstWhere((row) => row.id == other.id);
      expect(untouched.notifications.departedAt, isNull);
    });
  });

  group('pending arrival reminders', () {
    final scheduledFor = DateTime.utc(2026, 3, 17, 15);

    test('remembers when the system is due to deliver a reminder', () async {
      final flight = await addFlight();

      await repository.setArrivingSoonSchedule(flight.id, scheduledFor);

      final stored = (await repository.watchFlights().first).single;
      expect(stored.notifications.arrivingSoonScheduledFor, scheduledFor);
    });

    test('takes a reminder back off the record', () async {
      final flight = await addFlight();
      await repository.setArrivingSoonSchedule(flight.id, scheduledFor);

      await repository.setArrivingSoonSchedule(flight.id, null);

      final stored = (await repository.watchFlights().first).single;
      expect(stored.notifications.arrivingSoonScheduledFor, isNull);
    });

    test('counts a reminder whose moment has passed as delivered', () async {
      final flight = await addFlight();
      await repository.setArrivingSoonSchedule(flight.id, scheduledFor);

      await repository.markDueRemindersDelivered(
        scheduledFor.add(const Duration(minutes: 1)),
      );

      final stored = (await repository.watchFlights().first).single;
      expect(stored.notifications.arrivingSoonAt, scheduledFor);
      expect(stored.notifications.arrivingSoonScheduledFor, isNull);
    });

    test('leaves a reminder that is still ahead pending', () async {
      final flight = await addFlight();
      await repository.setArrivingSoonSchedule(flight.id, scheduledFor);

      await repository.markDueRemindersDelivered(
        scheduledFor.subtract(const Duration(minutes: 1)),
      );

      final stored = (await repository.watchFlights().first).single;
      expect(stored.notifications.arrivingSoonAt, isNull);
      expect(stored.notifications.arrivingSoonScheduledFor, scheduledFor);
    });
  });

  test('writes and clears the identity of a flight', () async {
    final flight = await addFlight();

    await repository.updateIdentity(
      flight.id,
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH433',
    );

    final found = (await repository.watchFlights().first).single;
    expect(found.hexAddress, '3c64c6');
    expect(found.expectedCallsign, 'DLH433');

    await repository.updateIdentity(
      flight.id,
      hexAddress: null,
      expectedCallsign: null,
    );

    final cleared = (await repository.watchFlights().first).single;
    expect(cleared.hexAddress, isNull);
    expect(cleared.expectedCallsign, isNull);
  });

  test('updates the identity of only the addressed flight', () async {
    final first = await addFlight();
    final second = await addFlight();

    await repository.updateIdentity(
      first.id,
      hexAddress: '3c64c6',
      expectedCallsign: 'DLH433',
    );

    final stored = await repository.watchFlights().first;
    expect(
      stored.firstWhere((flight) => flight.id == second.id).hexAddress,
      isNull,
    );
  });

  test('persists the latched tracking facts and the full position', () async {
    final flight = await addFlight();
    final timestamp = DateTime.utc(2026, 3, 17, 9, 41, 12, 345);
    final tracking = FlightTracking(
      latestPosition: position(timestamp, onGround: true),
      hasBeenAirborne: true,
      lastKnownOnGround: true,
    );

    await repository.updateTracking(flight.id, tracking);

    final stored = (await repository.watchFlights().first).single;
    expect(stored.tracking.hasBeenAirborne, isTrue);
    expect(stored.tracking.lastKnownOnGround, isTrue);

    final storedPosition = stored.tracking.latestPosition!;
    expect(storedPosition.timestamp, timestamp);
    expect(storedPosition.timestamp.isUtc, isTrue);
    expect(storedPosition.timestamp.millisecond, 345);
    expect(storedPosition.latitude, 49.875687);
    expect(storedPosition.longitude, 7.888834);
    expect(storedPosition.barometricAltitudeFeet, 34000);
    expect(storedPosition.onGround, isTrue);
    expect(storedPosition.geometricAltitudeFeet, 34500);
    expect(storedPosition.trackDegrees, 271.4);
    expect(storedPosition.trueHeadingDegrees, 269.8);
    expect(storedPosition.groundSpeedKnots, 451.2);
    expect(storedPosition.indicatedAirspeedKnots, 289.5);
    expect(storedPosition.mach, 0.784);
    expect(storedPosition.verticalRateFeetPerMinute, -640);

    expect(stored.lookupValue, 'LH433');
    expect(stored.departureDate, const CalendarDate(2026, 3, 17));
  });

  test('keeps a position whose optional fields are all absent', () async {
    final flight = await addFlight();
    final timestamp = DateTime.utc(2026, 3, 17, 9, 41);

    await repository.updateTracking(
      flight.id,
      FlightTracking(
        latestPosition: FixPosition(
          latitude: 49.875687,
          longitude: 7.888834,
          timestamp: timestamp,
        ),
      ),
    );

    final storedPosition =
        (await repository.watchFlights().first).single.tracking.latestPosition!;
    expect(storedPosition.timestamp, timestamp);
    expect(storedPosition.onGround, isNull);
    expect(storedPosition.barometricAltitudeFeet, isNull);
    expect(storedPosition.groundSpeedKnots, isNull);
    expect(storedPosition.verticalRateFeetPerMinute, isNull);
  });

  test('stores dates as ISO text, enums by name, and instants as '
      'epoch milliseconds', () async {
    final flight = await addFlight(
      departureDate: const CalendarDate(2026, 3, 17),
    );
    final timestamp = DateTime.utc(2026, 3, 17, 9, 41, 12, 345);
    await repository.updateTracking(
      flight.id,
      FlightTracking(latestPosition: position(timestamp)),
    );
    await repository.appendTrailPoint(
      flight.id,
      position(timestamp),
      SourceId.adsbfi,
    );

    final flightRow = await database
        .customSelect(
          'SELECT lookup_kind, departure_date, latest_timestamp FROM flights',
        )
        .getSingle();
    expect(flightRow.read<String>('lookup_kind'), 'flightNumber');
    expect(flightRow.read<String>('departure_date'), '2026-03-17');
    expect(
      flightRow.read<int>('latest_timestamp'),
      timestamp.millisecondsSinceEpoch,
    );

    final trailRow = await database
        .customSelect('SELECT source_id, timestamp FROM trail_points')
        .getSingle();
    expect(trailRow.read<String>('source_id'), 'adsbfi');
    expect(trailRow.read<int>('timestamp'), timestamp.millisecondsSinceEpoch);
  });

  test('clears the stored position when tracking has none', () async {
    final flight = await addFlight();
    await repository.updateTracking(
      flight.id,
      FlightTracking(
        latestPosition: position(DateTime.utc(2026, 3, 17, 9), onGround: false),
        hasBeenAirborne: true,
      ),
    );

    await repository.updateTracking(
      flight.id,
      const FlightTracking(hasBeenAirborne: true),
    );

    final stored = (await repository.watchFlights().first).single;
    expect(stored.tracking.latestPosition, isNull);
    expect(stored.tracking.hasBeenAirborne, isTrue);
  });

  test('updates only the addressed flight', () async {
    final first = await addFlight();
    final second = await addFlight();

    await repository.updateTracking(
      first.id,
      const FlightTracking(hasBeenAirborne: true, lastKnownOnGround: true),
    );

    final stored = await repository.watchFlights().first;
    expect(
      stored
          .firstWhere((flight) => flight.id == first.id)
          .tracking
          .hasBeenAirborne,
      isTrue,
    );
    expect(
      stored
          .firstWhere((flight) => flight.id == second.id)
          .tracking
          .hasBeenAirborne,
      isFalse,
    );
  });

  test('orders flights by departure date, then by id', () async {
    final nextDay = await addFlight(
      departureDate: const CalendarDate(2026, 3, 18),
    );
    final earlyFirst = await addFlight(
      departureDate: const CalendarDate(2026, 3, 17),
    );
    final earlySecond = await addFlight(
      departureDate: const CalendarDate(2026, 3, 17),
    );

    final stored = await repository.watchFlights().first;
    expect(stored.map((flight) => flight.id), [
      earlyFirst.id,
      earlySecond.id,
      nextDay.id,
    ]);
  });

  test('emits on insert, tracking update, and delete', () async {
    final emissions = <List<Flight>>[];
    final subscription = repository.watchFlights().listen(emissions.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    final flight = await addFlight();
    await pumpEventQueue();
    await repository.updateTracking(
      flight.id,
      const FlightTracking(hasBeenAirborne: true),
    );
    await pumpEventQueue();
    await repository.deleteFlight(flight.id);
    await pumpEventQueue();

    expect(emissions.map((flights) => flights.length), [0, 1, 1, 0]);
    expect(emissions[1].single.tracking.hasBeenAirborne, isFalse);
    expect(emissions[2].single.tracking.hasBeenAirborne, isTrue);
  });

  test('appends trail points and returns them ordered by timestamp', () async {
    final flight = await addFlight();
    final later = DateTime.utc(2026, 3, 17, 10, 15, 0, 500);
    final earlier = DateTime.utc(2026, 3, 17, 9, 15);

    await repository.appendTrailPoint(
      flight.id,
      position(later),
      SourceId.adsbfi,
    );
    await repository.appendTrailPoint(
      flight.id,
      position(earlier),
      SourceId.adsblol,
    );

    final trail = await repository.watchTrail(flight.id).first;
    expect(trail.map((point) => point.timestamp), [earlier, later]);
    expect(trail.map((point) => point.sourceId), [
      SourceId.adsblol,
      SourceId.adsbfi,
    ]);
    expect(trail.first.latitude, 49.875687);
    expect(trail.first.longitude, 7.888834);
    expect(trail.last.timestamp.millisecond, 500);
    expect(trail.last.timestamp.isUtc, isTrue);
  });

  test('ignores a repeated trail point with the same timestamp', () async {
    final flight = await addFlight();
    final timestamp = DateTime.utc(2026, 3, 17, 10, 15);

    await repository.appendTrailPoint(
      flight.id,
      position(timestamp),
      SourceId.adsblol,
    );
    await repository.appendTrailPoint(
      flight.id,
      FixPosition(latitude: 1, longitude: 2, timestamp: timestamp),
      SourceId.adsbfi,
    );

    final trail = await repository.watchTrail(flight.id).first;
    expect(trail, hasLength(1));
    expect(trail.single.latitude, 49.875687);
    expect(trail.single.sourceId, SourceId.adsblol);
  });

  test('keeps the trails of other flights apart', () async {
    final first = await addFlight();
    final second = await addFlight();
    final timestamp = DateTime.utc(2026, 3, 17, 10, 15);

    await repository.appendTrailPoint(
      first.id,
      position(timestamp),
      SourceId.adsblol,
    );
    await repository.appendTrailPoint(
      second.id,
      position(timestamp),
      SourceId.adsbfi,
    );

    expect(await repository.watchTrail(first.id).first, hasLength(1));
    expect(await repository.watchTrail(second.id).first, hasLength(1));
  });

  test('emits on trail append', () async {
    final flight = await addFlight();
    final emissions = <List<TrailPoint>>[];
    final subscription = repository.watchTrail(flight.id).listen(emissions.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.appendTrailPoint(
      flight.id,
      position(DateTime.utc(2026, 3, 17, 10, 15)),
      SourceId.adsblol,
    );
    await pumpEventQueue();

    expect(emissions.map((trail) => trail.length), [0, 1]);
  });

  test('deletes a flight together with its trail points', () async {
    final flight = await addFlight();
    final survivor = await addFlight();
    await repository.appendTrailPoint(
      flight.id,
      position(DateTime.utc(2026, 3, 17, 10, 15)),
      SourceId.adsblol,
    );
    await repository.appendTrailPoint(
      survivor.id,
      position(DateTime.utc(2026, 3, 17, 10, 15)),
      SourceId.adsblol,
    );

    await repository.deleteFlight(flight.id);

    expect(await repository.watchTrail(flight.id).first, isEmpty);
    expect(await repository.watchTrail(survivor.id).first, hasLength(1));
    expect((await repository.watchFlights().first).map((f) => f.id), [
      survivor.id,
    ]);
  });

  test('deletes only the flights that have expired', () async {
    await addFlight();
    final upcoming = await addFlight(
      departureDate: const CalendarDate(2026, 3, 18),
    );

    await repository.deleteExpiredFlights(window.end.add(pastFlightRetention));

    expect((await repository.watchFlights().first).map((flight) => flight.id), [
      upcoming.id,
    ]);
  });

  test('deletes the trail points of an expired flight', () async {
    final expired = await addFlight();
    final upcoming = await addFlight(
      departureDate: const CalendarDate(2026, 3, 18),
    );
    for (final flight in [expired, upcoming]) {
      await repository.appendTrailPoint(
        flight.id,
        position(window.start.add(const Duration(hours: 2)).toUtc()),
        SourceId.adsblol,
      );
    }

    await repository.deleteExpiredFlights(window.end.add(pastFlightRetention));

    expect(await repository.watchTrail(expired.id).first, isEmpty);
    expect(await repository.watchTrail(upcoming.id).first, hasLength(1));
  });

  test('deletes an early landed flight while its window is open', () async {
    final landed = await addFlight();
    final stillRunning = await addFlight();
    final landing = window.start.add(const Duration(hours: 2)).toUtc();
    await repository.updateTracking(
      landed.id,
      FlightTracking(
        latestPosition: position(landing, onGround: true),
        hasBeenAirborne: true,
        lastKnownOnGround: true,
      ),
    );

    final now = landing.add(pastFlightRetention);
    expect(window.contains(now), isTrue);
    await repository.deleteExpiredFlights(now);

    expect((await repository.watchFlights().first).map((flight) => flight.id), [
      stillRunning.id,
    ]);
  });

  test('emits the shortened list once flights expire', () async {
    await addFlight();
    final emissions = <List<Flight>>[];
    final subscription = repository.watchFlights().listen(emissions.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await repository.deleteExpiredFlights(window.end.add(pastFlightRetention));
    await pumpEventQueue();

    expect(emissions.map((flights) => flights.length), [1, 0]);
  });

  group('route', () {
    const route = FlightRoute(
      origin: RouteAirport(
        icaoCode: 'EDDF',
        iataCode: 'FRA',
        name: 'Frankfurt Airport',
        location: 'Frankfurt-am-Main',
        latitude: 50.026402,
        longitude: 8.543130,
      ),
      destination: RouteAirport(
        icaoCode: 'KJFK',
        name: 'John F Kennedy Airport',
        latitude: 40.639447,
        longitude: -73.779317,
      ),
    );

    test('round-trips a route through the database', () async {
      final added = await repository.addFlight(
        lookupKind: FlightLookupKind.flightNumber,
        lookupValue: 'LH400',
        departureDate: const CalendarDate(2026, 3, 17),
        route: route,
      );

      final stored = (await repository.watchFlights().first).single.route!;
      expect(added.route?.origin.icaoCode, 'EDDF');
      expect(stored.origin.icaoCode, 'EDDF');
      expect(stored.origin.iataCode, 'FRA');
      expect(stored.origin.name, 'Frankfurt Airport');
      expect(stored.origin.location, 'Frankfurt-am-Main');
      expect(stored.origin.latitude, 50.026402);
      expect(stored.origin.longitude, 8.543130);
      expect(stored.destination.icaoCode, 'KJFK');
      expect(stored.destination.name, 'John F Kennedy Airport');
      expect(stored.destination.latitude, 40.639447);
      expect(stored.destination.longitude, -73.779317);
    });

    test('keeps an absent iata code and location null', () async {
      await repository.addFlight(
        lookupKind: FlightLookupKind.flightNumber,
        lookupValue: 'LH400',
        departureDate: const CalendarDate(2026, 3, 17),
        route: route,
      );

      final stored = (await repository.watchFlights().first).single.route!;
      expect(stored.destination.iataCode, isNull);
      expect(stored.destination.location, isNull);
    });

    test('reads back no route for a flight added without one', () async {
      await addFlight();

      expect((await repository.watchFlights().first).single.route, isNull);
    });
  });
}
