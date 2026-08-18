import 'package:flugwacht/data/notifications/flight_notifier.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

const _departureDate = CalendarDate(2026, 3, 17);

const _route = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDF',
    iataCode: 'FRA',
    name: 'Frankfurt am Main',
    latitude: 50.026402,
    longitude: 8.543130,
  ),
  destination: RouteAirport(
    icaoCode: 'EDDM',
    iataCode: 'MUC',
    name: 'München',
    latitude: 48.353802,
    longitude: 11.786100,
  ),
);

final _now = DateTime.utc(2026, 3, 17, 12);

FixPosition _position({
  required double groundSpeedKnots,
  bool onGround = false,
}) => FixPosition(
  latitude: 50.026402,
  longitude: 8.543130,
  timestamp: _now,
  onGround: onGround,
  groundSpeedKnots: groundSpeedKnots,
);

const _flight = Flight(
  id: 7,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH400',
  departureDate: _departureDate,
  note: 'Anna & Ben',
  route: _route,
);

void main() {
  late FakeFlightRepository repository;
  late FakeNotificationService service;
  late FakeNotificationSetting setting;
  late FlightNotifier notifier;
  late DateTime now;

  setUp(() {
    now = _now;
    repository = FakeFlightRepository();
    addTearDown(repository.dispose);
    service = createTestNotificationService();
    setting = FakeNotificationSetting();
    notifier = FlightNotifier(
      repository: repository,
      service: service,
      setting: setting,
      copy: (kind, flight) => (title: flight.lookupValue, body: kind.name),
      clock: () => now,
    );
  });

  test('delivers a departure and remembers that it went out', () async {
    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 30),
        hasBeenAirborne: true,
      ),
    );

    expect(service.shown, [(FlightNotification.departed, 7)]);
    expect(repository.notificationMarks, [(7, FlightNotification.departed)]);
  });

  test('marks nothing while the service is unavailable', () async {
    final unavailableService = UnavailableNotificationService();
    addTearDown(unavailableService.dispose);
    final quietNotifier = FlightNotifier(
      repository: repository,
      service: unavailableService,
      setting: setting,
      copy: (kind, flight) => (title: flight.lookupValue, body: kind.name),
      clock: () => now,
    );

    await quietNotifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 30),
        hasBeenAirborne: true,
      ),
    );
    await quietNotifier.reconcileDeliveredReminders();

    expect(repository.notificationMarks, isEmpty);
  });

  test('delivers nothing while its switch is off', () async {
    setting.enabled = const {};

    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 30),
        hasBeenAirborne: true,
      ),
    );

    expect(service.shown, isEmpty);
    expect(repository.notificationMarks, isEmpty);
  });

  test('hands the arrival reminder to the system ahead of time', () async {
    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 180),
        hasBeenAirborne: true,
      ),
    );

    final (kind, flightId, at) = service.scheduled.single;
    expect(kind, FlightNotification.arrivingSoon);
    expect(flightId, 7);
    expect(at.isAfter(_now), isTrue);
  });

  test('takes the reminder back when the flight lands', () async {
    final airborne = FlightTracking(
      latestPosition: _position(groundSpeedKnots: 180),
      hasBeenAirborne: true,
    );
    await notifier.trackingChanged(_flight, airborne);

    await notifier.trackingChanged(
      _flight.copyWith(
        tracking: airborne,
        notifications: NotificationMarkers(
          arrivingSoonScheduledFor: service.scheduled.single.$3,
        ),
      ),
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 10, onGround: true),
        hasBeenAirborne: true,
        lastKnownOnGround: true,
      ),
    );

    expect(service.shown, contains((FlightNotification.landed, 7)));
    expect(service.cancelled, [(FlightNotification.arrivingSoon, 7)]);
  });

  test('shows nothing twice when a poll carries an older flight', () async {
    final airborne = FlightTracking(
      latestPosition: _position(groundSpeedKnots: 30),
      hasBeenAirborne: true,
    );
    await notifier.trackingChanged(_flight, airborne);

    await notifier.trackingChanged(_flight, airborne);

    expect(service.shown, [(FlightNotification.departed, 7)]);
  });

  test('takes the reminder of a flight that is gone back', () async {
    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 180),
        hasBeenAirborne: true,
      ),
    );

    await notifier.flightsRemoved(const [7]);

    expect(service.cancelled, [(FlightNotification.arrivingSoon, 7)]);
  });

  test('counts a reminder whose moment has passed as delivered', () async {
    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 180),
        hasBeenAirborne: true,
      ),
    );
    now = service.scheduled.single.$3.add(const Duration(minutes: 1));

    await notifier.reconcileDeliveredReminders();

    expect(
      repository.notificationMarks,
      contains((7, FlightNotification.arrivingSoon)),
    );
  });

  test('counts the reminder an earlier run scheduled as delivered', () async {
    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 180),
        hasBeenAirborne: true,
      ),
    );
    now = service.scheduled.single.$3.add(const Duration(minutes: 1));
    final afterRestart = FlightNotifier(
      repository: repository,
      service: service,
      setting: setting,
      copy: (kind, flight) => (title: flight.lookupValue, body: kind.name),
      clock: () => now,
    );

    await afterRestart.reconcileDeliveredReminders();

    expect(
      repository.notificationMarks,
      contains((7, FlightNotification.arrivingSoon)),
    );
  });

  test('leaves a reminder that is still ahead pending', () async {
    await notifier.trackingChanged(
      _flight,
      FlightTracking(
        latestPosition: _position(groundSpeedKnots: 180),
        hasBeenAirborne: true,
      ),
    );

    await notifier.reconcileDeliveredReminders();

    expect(
      repository.notificationMarks,
      isNot(contains((7, FlightNotification.arrivingSoon))),
    );
  });
}
