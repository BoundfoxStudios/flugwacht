import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flugwacht/data/live_activities/flight_live_activities.dart';
import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/data/persistence/database.dart';
import 'package:flugwacht/data/persistence/flight_repository.dart';
import 'package:flugwacht/data/settings/live_activity_setting.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/live_activity_planning.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

void main() {
  late AppDatabase database;
  late FlightRepository repository;
  late FakeLiveActivityService service;
  late FakeNotificationService notifications;
  late LiveActivitySetting setting;
  late FlightLiveActivities activities;

  final onFlightDay = DateTime(2026, 3, 17, 12);
  final beforeFlightDay = DateTime(2026, 3, 16, 12);
  var now = onFlightDay;

  setUp(() async {
    now = onFlightDay;
    database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = FlightRepository(database);
    service = FakeLiveActivityService();
    notifications = createTestNotificationService(
      permission: NotificationPermission.granted,
    );
    setting = await createTestLiveActivitySetting();
    activities = FlightLiveActivities(
      repository: repository,
      service: service,
      notifications: notifications,
      setting: setting,
      copy: (flight) => (title: 'Live Activity', body: flight.lookupValue),
      clock: () => now,
    );
  });

  tearDown(() => database.close());

  Future<Flight> addFlight({bool isArmed = true, DayTime? departureTime}) =>
      repository.addFlight(
        lookupKind: FlightLookupKind.flightNumber,
        lookupValue: 'LH433',
        departureDate: const CalendarDate(2026, 3, 17),
        departureTime: departureTime,
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
    service.availability.value = LiveActivityAvailability.disabled;
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

  test('asks about the activity under the id it started it with', () async {
    await addFlight();
    await activities.flightsChanged(await storedFlights());
    final activityId = service.puts.single.activityId;
    service.running = [activityId];

    await activities.reconcile(await storedFlights());

    expect((await storedFlight()).liveActivityId, activityId);
  });

  /// The everyday cold start: the flight stream lands while the resume pass is
  /// still running, so a reconcile can arrive between minting a card's id and
  /// the system confirming it.
  test('starts one card when a reconcile lands mid-start', () async {
    // A clock that moves, so two starts would mint two ids — a frozen one
    // makes them identical and hides the second card.
    var readings = 0;
    final ticking = FlightLiveActivities(
      repository: repository,
      service: service,
      notifications: notifications,
      setting: setting,
      copy: (flight) => (title: 'Live Activity', body: flight.lookupValue),
      clock: () => now.add(Duration(milliseconds: readings++)),
    );
    await addFlight();
    final flights = await storedFlights();
    service.held = Completer<void>();

    final starting = ticking.flightsChanged(flights);
    final reconciling = ticking.reconcile(flights);
    service.held!.complete();
    await Future.wait([starting, reconciling]);
    await ticking.flightsChanged(await storedFlights());

    expect(service.puts.map((put) => put.activityId).toSet(), hasLength(1));
    expect((await storedFlight()).liveActivityId, isNotNull);
  });

  test('keeps every other flight going when one card fails', () async {
    await addFlight();
    await repository.addFlight(
      lookupKind: FlightLookupKind.flightNumber,
      lookupValue: 'LH400',
      departureDate: const CalendarDate(2026, 3, 17),
      liveActivityArmed: true,
    );
    service.failure = Exception('the system refused the card');

    await activities.flightsChanged(await storedFlights());

    service.failure = null;
    await activities.flightsChanged(await storedFlights());

    expect(service.puts.map((put) => put.activityId).toSet(), hasLength(2));
  });

  test('remembers a card whose first put failed', () async {
    await addFlight();
    service.failure = Exception('the system refused the card');
    await activities.flightsChanged(await storedFlights());

    service.failure = null;
    await activities.flightsChanged(await storedFlights());

    expect((await storedFlight()).liveActivityId, service.puts.last.activityId);
  });

  group('flight day reminder', () {
    test('schedules it two hours before the departure', () async {
      now = beforeFlightDay;
      await addFlight(departureTime: const DayTime(10, 0));

      await activities.flightsChanged(await storedFlights());

      expect(notifications.scheduledReminders, [(1, DateTime(2026, 3, 17, 8))]);
    });

    test('remembers the moment the system is due to deliver it', () async {
      now = beforeFlightDay;
      await addFlight(departureTime: const DayTime(10, 0));

      await activities.flightsChanged(await storedFlights());

      expect(
        (await storedFlight()).liveActivityReminderScheduledFor,
        DateTime(2026, 3, 17, 8).toUtc(),
      );
    });

    test('leaves a reminder that already sits on that moment alone', () async {
      now = beforeFlightDay;
      await addFlight(departureTime: const DayTime(10, 0));
      await activities.flightsChanged(await storedFlights());

      await activities.flightsChanged(await storedFlights());

      expect(notifications.scheduledReminders, hasLength(1));
    });

    test('schedules none while the setting is off', () async {
      now = beforeFlightDay;
      await setting.selectReminder(isEnabled: false);
      await addFlight(departureTime: const DayTime(10, 0));

      await activities.flightsChanged(await storedFlights());

      expect(notifications.scheduledReminders, isEmpty);
    });

    test('schedules none without the permission to notify', () async {
      now = beforeFlightDay;
      notifications.permission.value = NotificationPermission.denied;
      await addFlight(departureTime: const DayTime(10, 0));

      await activities.flightsChanged(await storedFlights());

      expect(notifications.scheduledReminders, isEmpty);
    });

    test('takes the reminder of a flight that was disarmed back', () async {
      now = beforeFlightDay;
      final flight = await addFlight(departureTime: const DayTime(10, 0));
      await activities.flightsChanged(await storedFlights());
      await repository.setLiveActivityArmed(flight.id, isArmed: false);

      await activities.flightsChanged(await storedFlights());

      expect(notifications.cancelledReminders, [flight.id]);
      expect((await storedFlight()).liveActivityReminderScheduledFor, isNull);
    });

    test('takes the reminder of a flight that is gone back', () async {
      now = beforeFlightDay;
      await addFlight(departureTime: const DayTime(10, 0));
      await activities.flightsChanged(await storedFlights());
      final gone = await storedFlight();

      await activities.flightsRemoved([gone]);

      expect(notifications.cancelledReminders, [gone.id]);
    });
  });
}
