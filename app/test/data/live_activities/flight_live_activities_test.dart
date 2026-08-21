import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flugwacht/data/live_activities/flight_live_activities.dart';
import 'package:flugwacht/data/persistence/database.dart';
import 'package:flugwacht/data/persistence/flight_repository.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/live_activity_planning.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

void main() {
  late AppDatabase database;
  late FlightRepository repository;
  late FakeLiveActivityService service;
  late FlightLiveActivities activities;

  final onFlightDay = DateTime(2026, 3, 17, 12);

  setUp(() {
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = FlightRepository(database);
    service = FakeLiveActivityService();
    activities = FlightLiveActivities(
      repository: repository,
      service: service,
      clock: () => onFlightDay,
    );
  });

  tearDown(() => database.close());

  Future<Flight> addFlight({bool isArmed = true}) => repository.addFlight(
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH433',
    departureDate: const CalendarDate(2026, 3, 17),
    liveActivityArmed: isArmed,
  );

  Future<List<Flight>> storedFlights() => repository.watchFlights().first;

  Future<Flight> storedFlight() async => (await storedFlights()).single;

  test('starts an activity for an armed flight and remembers it', () async {
    await addFlight();

    await activities.flightsChanged(await storedFlights());

    expect(service.puts, hasLength(1));
    expect(
      (await storedFlight()).liveActivityId,
      service.puts.single.activityId,
    );
  });

  test('puts the flight on the card it starts', () async {
    await addFlight();

    await activities.flightsChanged(await storedFlights());

    expect(service.puts.single.data['designator'], 'LH433');
  });

  test('starts nothing while iOS has live activities switched off', () async {
    service.isEnabled = false;
    await addFlight();

    await activities.flightsChanged(await storedFlights());

    expect(service.puts, isEmpty);
    expect((await storedFlight()).liveActivityId, isNull);
  });

  test('starts nothing for a flight that is not armed', () async {
    await addFlight(isArmed: false);

    await activities.flightsChanged(await storedFlights());

    expect(service.puts, isEmpty);
  });

  test('updates the activity it already started', () async {
    await addFlight();
    await activities.flightsChanged(await storedFlights());
    final activityId = service.puts.single.activityId;

    await activities.flightsChanged(await storedFlights());

    expect(service.puts, hasLength(2));
    expect(service.puts.last.activityId, activityId);
    expect(service.ends, isEmpty);
  });

  test('ends the activity of a flight that was disarmed', () async {
    final flight = await addFlight();
    await activities.flightsChanged(await storedFlights());
    final activityId = service.puts.single.activityId;
    await repository.setLiveActivityArmed(flight.id, isArmed: false);

    await activities.flightsChanged(await storedFlights());

    expect(service.ends.single.activityId, activityId);
    expect(service.ends.single.dismissAt, isNull);
    expect((await storedFlight()).liveActivityId, isNull);
  });

  test('lets a landed card stand for the grace period', () async {
    final flight = await addFlight();
    await activities.flightsChanged(await storedFlights());
    await repository.updateTracking(
      flight.id,
      FlightTracking(
        latestPosition: FixPosition(
          latitude: 49.875687,
          longitude: 7.888834,
          timestamp: onFlightDay,
          onGround: true,
        ),
        hasBeenAirborne: true,
        lastKnownOnGround: true,
      ),
    );

    await activities.flightsChanged(await storedFlights());

    expect(service.ends.single.dismissAt, onFlightDay.add(landedActivityGrace));
    expect((await storedFlight()).liveActivityId, isNull);
  });

  test('shows the landing before it lets the card go', () async {
    final flight = await addFlight();
    await activities.flightsChanged(await storedFlights());
    await repository.updateTracking(
      flight.id,
      FlightTracking(
        latestPosition: FixPosition(
          latitude: 49.875687,
          longitude: 7.888834,
          timestamp: onFlightDay,
          onGround: true,
        ),
        hasBeenAirborne: true,
        lastKnownOnGround: true,
      ),
    );

    await activities.flightsChanged(await storedFlights());

    expect(service.puts.last.data['state'], 'ended');
  });

  test('ends the activity of a flight that is gone', () async {
    await addFlight();
    await activities.flightsChanged(await storedFlights());
    final gone = await storedFlight();

    await activities.flightsRemoved([gone]);

    expect(service.ends.single.activityId, gone.liveActivityId);
  });

  test('ends nothing for a gone flight that had no activity', () async {
    await addFlight(isArmed: false);

    await activities.flightsRemoved(await storedFlights());

    expect(service.ends, isEmpty);
  });

  test('forgets an activity the system no longer runs', () async {
    await addFlight();
    await activities.flightsChanged(await storedFlights());
    service.running = const [];

    await activities.reconcile(await storedFlights());

    expect((await storedFlight()).liveActivityId, isNull);
  });

  test('keeps an activity the system still runs', () async {
    await addFlight();
    await activities.flightsChanged(await storedFlights());
    final activityId = service.puts.single.activityId;
    service.running = [activityId];

    await activities.reconcile(await storedFlights());

    expect((await storedFlight()).liveActivityId, activityId);
  });
}
