import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/notification_planning.dart';
import 'package:flutter_test/flutter_test.dart';

const _departureDate = CalendarDate(2026, 3, 17);

/// Frankfurt to Munich, so a position over Frankfurt is a known distance out.
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

/// A position over Frankfurt; the ground speed sets how far Munich is in time.
FixPosition _position({
  required double groundSpeedKnots,
  DateTime? timestamp,
  bool onGround = false,
}) => FixPosition(
  latitude: 50.026402,
  longitude: 8.543130,
  timestamp: timestamp ?? _now,
  onGround: onGround,
  groundSpeedKnots: groundSpeedKnots,
);

Flight _flight({
  FlightTracking tracking = const FlightTracking(),
  NotificationMarkers notifications = const NotificationMarkers(),
  FlightRoute? route = _route,
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH400',
  departureDate: _departureDate,
  route: route,
  tracking: tracking,
  notifications: notifications,
);

NotificationPlan _plan({
  required Flight flight,
  FlightTracking previousTracking = const FlightTracking(),
  DateTime? pendingArrivingSoonAt,
  Set<FlightNotification> enabled = const {
    FlightNotification.departed,
    FlightNotification.arrivingSoon,
    FlightNotification.landed,
  },
  DateTime? now,
}) => planNotifications(
  flight: flight,
  previousTracking: previousTracking,
  pendingArrivingSoonAt: pendingArrivingSoonAt,
  isEnabled: enabled.contains,
  now: now ?? _now,
);

void main() {
  group('departed', () {
    test('fires on the first airborne fix', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 30),
            hasBeenAirborne: true,
          ),
        ),
      );

      expect(plan.events, contains(FlightNotification.departed));
    });

    test('stays quiet while the flight has not left the ground', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 5, onGround: true),
          ),
        ),
      );

      expect(plan.events, isEmpty);
    });

    test('fires only once per flight', () {
      final tracking = FlightTracking(
        latestPosition: _position(groundSpeedKnots: 30),
        hasBeenAirborne: true,
      );
      final plan = _plan(
        flight: _flight(
          tracking: tracking,
          notifications: NotificationMarkers(departedAt: _now),
        ),
        previousTracking: const FlightTracking(),
      );

      expect(plan.events, isNot(contains(FlightNotification.departed)));
    });

    test('stays quiet for a flight that was already airborne', () {
      final tracking = FlightTracking(
        latestPosition: _position(groundSpeedKnots: 30),
        hasBeenAirborne: true,
      );
      final plan = _plan(
        flight: _flight(tracking: tracking),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isNot(contains(FlightNotification.departed)));
    });

    test('stays quiet while its switch is off', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 30),
            hasBeenAirborne: true,
          ),
        ),
        enabled: const {
          FlightNotification.arrivingSoon,
          FlightNotification.landed,
        },
      );

      expect(plan.events, isEmpty);
    });
  });

  group('landed', () {
    FlightTracking landedTracking() => FlightTracking(
      latestPosition: _position(groundSpeedKnots: 10, onGround: true),
      hasBeenAirborne: true,
      lastKnownOnGround: true,
    );

    test('fires when an airborne flight is back on the ground', () {
      final plan = _plan(
        flight: _flight(tracking: landedTracking()),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, contains(FlightNotification.landed));
    });

    test('stays quiet for a flight that never left the ground', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 0, onGround: true),
            lastKnownOnGround: true,
          ),
        ),
      );

      expect(plan.events, isEmpty);
    });

    test('fires only once per flight', () {
      final plan = _plan(
        flight: _flight(
          tracking: landedTracking(),
          notifications: NotificationMarkers(landedAt: _now),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isEmpty);
    });

    test('cancels a pending arrival reminder', () {
      final plan = _plan(
        flight: _flight(tracking: landedTracking()),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: _now.add(const Duration(minutes: 10)),
      );

      expect(plan.schedule, isA<CancelArrivingSoonSchedule>());
    });
  });

  group('arriving soon', () {
    /// Frankfurt to Munich is roughly 300 km, so 720 kn leaves about a quarter
    /// of an hour and 180 kn leaves about an hour.
    test('fires as soon as a fresh estimate is within half an hour', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 720),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: _now.add(const Duration(minutes: 20)),
      );

      expect(plan.events, contains(FlightNotification.arrivingSoon));
      expect(plan.schedule, isA<CancelArrivingSoonSchedule>());
    });

    test('stays quiet for a flight first seen inside the window', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 720),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isEmpty);
    });

    test('schedules no reminder for a flight first seen inside it', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 720),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.schedule, isA<KeepArrivingSoonSchedule>());
    });

    test('stays quiet once the estimated arrival has passed', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(
              groundSpeedKnots: 2000,
              timestamp: _now.subtract(const Duration(minutes: 10)),
            ),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: _now.subtract(const Duration(minutes: 35)),
      );

      expect(plan.events, isEmpty);
    });

    test('stays quiet while the estimate is further out', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 180),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isEmpty);
    });

    test('stays quiet without a route to estimate against', () {
      final plan = _plan(
        flight: _flight(
          route: null,
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 720),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isEmpty);
    });

    test('never fires from a stale position', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(
              groundSpeedKnots: 720,
              timestamp: _now.subtract(const Duration(minutes: 42)),
            ),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isEmpty);
    });

    test('fires only once per flight', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 720),
            hasBeenAirborne: true,
          ),
          notifications: NotificationMarkers(arrivingSoonAt: _now),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.events, isEmpty);
    });

    test('stays quiet while its switch is off', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 720),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        enabled: const {FlightNotification.departed, FlightNotification.landed},
      );

      expect(plan.events, isEmpty);
    });
  });

  group('the pre-scheduled reminder', () {
    Flight cruising() => _flight(
      tracking: FlightTracking(
        latestPosition: _position(groundSpeedKnots: 180),
        hasBeenAirborne: true,
      ),
    );

    test('is set half an hour before the estimated arrival', () {
      final plan = _plan(
        flight: cruising(),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      final schedule = plan.schedule;
      expect(schedule, isA<SetArrivingSoonSchedule>());
      final arrival = (schedule as SetArrivingSoonSchedule).at.add(
        arrivingSoonLeadTime,
      );
      expect(
        arrival.difference(_now).inMinutes,
        closeTo(54, 5),
        reason: 'roughly 300 km at 180 kn',
      );
    });

    test('stays as it is while the estimate barely moves', () {
      final firstPlan = _plan(
        flight: cruising(),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );
      final scheduledAt = (firstPlan.schedule as SetArrivingSoonSchedule).at;

      final plan = _plan(
        flight: cruising(),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: scheduledAt.add(const Duration(seconds: 20)),
      );

      expect(plan.schedule, isA<KeepArrivingSoonSchedule>());
    });

    test('moves with an estimate that changed', () {
      final plan = _plan(
        flight: cruising(),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: _now.add(const Duration(hours: 3)),
      );

      expect(plan.schedule, isA<SetArrivingSoonSchedule>());
    });

    test('is left alone while no fresh estimate says otherwise', () {
      final pending = _now.add(const Duration(minutes: 40));
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(
              groundSpeedKnots: 180,
              timestamp: _now.subtract(const Duration(minutes: 42)),
            ),
            hasBeenAirborne: true,
          ),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: pending,
      );

      expect(plan.schedule, isA<KeepArrivingSoonSchedule>());
    });

    test('is cancelled while the switch is off', () {
      final plan = _plan(
        flight: cruising(),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
        pendingArrivingSoonAt: _now.add(const Duration(minutes: 40)),
        enabled: const {FlightNotification.departed, FlightNotification.landed},
      );

      expect(plan.schedule, isA<CancelArrivingSoonSchedule>());
    });

    test('is not set for a flight that has already been reminded', () {
      final plan = _plan(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(groundSpeedKnots: 180),
            hasBeenAirborne: true,
          ),
          notifications: NotificationMarkers(arrivingSoonAt: _now),
        ),
        previousTracking: const FlightTracking(hasBeenAirborne: true),
      );

      expect(plan.schedule, isA<KeepArrivingSoonSchedule>());
    });
  });
}
