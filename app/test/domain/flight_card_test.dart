import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_card.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const departureDate = CalendarDate(2026, 3, 17);
  final onFlightDay = DateTime(2026, 3, 17, 12);

  RouteAirport airport(String code, double latitude, double longitude) =>
      RouteAirport(
        iataCode: code,
        icaoCode: 'X$code',
        name: code,
        latitude: latitude,
        longitude: longitude,
      );

  final route = FlightRoute(
    origin: airport('FRA', 50.0379, 8.5622),
    destination: airport('JFK', 40.6413, -73.7781),
  );

  /// A fix close enough to the destination that the estimate lands minutes
  /// away, so a test can put the arrival on either side of the clock.
  FixPosition approaching({
    required DateTime at,
    double longitude = -73.0,
    bool onGround = false,
    double groundSpeedKnots = 400,
  }) => FixPosition(
    latitude: 40.6413,
    longitude: longitude,
    timestamp: at,
    onGround: onGround,
    groundSpeedKnots: groundSpeedKnots,
  );

  Flight flight({
    String? note,
    FlightRoute? withRoute,
    DayTime? departureTime,
    FlightTracking tracking = const FlightTracking(),
  }) => Flight(
    id: 1,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH433',
    departureDate: departureDate,
    departureTime: departureTime,
    note: note,
    route: withRoute,
    tracking: tracking,
  );

  test('names the flight and its note the way every screen does', () {
    final card = flightCardOf(flight(note: 'Mama'), onFlightDay);

    expect(card.designator, 'LH433');
    expect(card.note, 'Mama');
  });

  test('carries the route in IATA codes', () {
    final card = flightCardOf(flight(withRoute: route), onFlightDay);

    expect(card.route?.origin, 'FRA');
    expect(card.route?.destination, 'JFK');
  });

  test('leaves out a route the flight has only one end of', () {
    final card = flightCardOf(flight(), onFlightDay);

    expect(card.route, isNull);
  });

  group('countdown', () {
    test('runs to the departure while the flight waits for its signal', () {
      final card = flightCardOf(
        flight(departureTime: const DayTime(14, 30)),
        onFlightDay,
      );

      expect(card.countdown?.label, FlightCardCountdown.departure);
      expect(card.countdown?.at, DateTime(2026, 3, 17, 14, 30));
    });

    test('runs to the arrival once the flight is in the air', () {
      final card = flightCardOf(
        flight(
          withRoute: route,
          tracking: FlightTracking(
            firstAirborneAt: onFlightDay.subtract(const Duration(hours: 7)),
            latestPosition: approaching(at: onFlightDay),
          ),
        ),
        onFlightDay,
      );

      expect(card.countdown?.label, FlightCardCountdown.arrival);
      expect(card.countdown?.at.isAfter(onFlightDay), isTrue);
    });

    /// A countdown to a moment that has passed would start counting up, which
    /// is the one thing the system-drawn timer cannot be told not to do.
    test('stops once the moment it counted to has passed', () {
      final departed = flight(departureTime: const DayTime(10, 0));

      final card = flightCardOf(departed, onFlightDay);

      expect(card.countdown, isNull);
    });

    test('has nothing to count to once the flight is down', () {
      final landed = flight(
        withRoute: route,
        tracking: FlightTracking(
          hasBeenAirborne: true,
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 7)),
          lastKnownOnGround: true,
          latestPosition: approaching(at: onFlightDay, onGround: true),
        ),
      );

      final card = flightCardOf(landed, onFlightDay);

      expect(card.countdown, isNull);
    });
  });

  group('probably landed', () {
    test('says so once the estimate ran out with the flight still up', () {
      final overdue = flight(
        withRoute: route,
        tracking: FlightTracking(
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 8)),
          latestPosition: approaching(
            at: onFlightDay.subtract(const Duration(minutes: 20)),
            longitude: -73.75,
          ),
        ),
      );

      final card = flightCardOf(overdue, onFlightDay);

      expect(card.state, FlightState.noSignal);
      expect(card.hasProbablyLanded, isTrue);
      expect(card.countdown, isNull);
    });

    test('says so while the signal is still fresh but the estimate is not', () {
      final overdue = flight(
        withRoute: route,
        tracking: FlightTracking(
          hasBeenAirborne: true,
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 8)),
          latestPosition: approaching(
            at: onFlightDay.subtract(const Duration(minutes: 5)),
            longitude: -73.72,
          ),
        ),
      );

      final card = flightCardOf(overdue, onFlightDay);

      expect(card.state, FlightState.live);
      expect(card.hasProbablyLanded, isTrue);
    });

    test('says nothing of the sort while the estimate is still ahead', () {
      final enRoute = flight(
        withRoute: route,
        tracking: FlightTracking(
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 7)),
          latestPosition: approaching(at: onFlightDay),
        ),
      );

      final card = flightCardOf(enRoute, onFlightDay);

      expect(card.hasProbablyLanded, isFalse);
    });

    test('says nothing of the sort about a flight that is down', () {
      final landed = flight(
        withRoute: route,
        tracking: FlightTracking(
          hasBeenAirborne: true,
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 8)),
          lastKnownOnGround: true,
          latestPosition: approaching(at: onFlightDay, onGround: true),
        ),
      );

      final card = flightCardOf(landed, onFlightDay);

      expect(card.hasProbablyLanded, isFalse);
    });
  });

  group('landing', () {
    test('shows when the flight touched down and drops its estimate', () {
      final touchdown = onFlightDay.subtract(const Duration(minutes: 5));
      final landed = flight(
        withRoute: route,
        tracking: FlightTracking(
          hasBeenAirborne: true,
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 8)),
          lastKnownOnGround: true,
          latestPosition: approaching(at: touchdown, onGround: true),
        ),
      );

      final card = flightCardOf(landed, onFlightDay);

      expect(card.state, FlightState.ended);
      expect(card.landedAt, touchdown);
      expect(card.arrivesAt, isNull);
    });

    test('has no landing while the flight is still up', () {
      final enRoute = flight(
        withRoute: route,
        tracking: FlightTracking(
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 7)),
          latestPosition: approaching(at: onFlightDay),
        ),
      );

      expect(flightCardOf(enRoute, onFlightDay).landedAt, isNull);
    });
  });

  group('progress', () {
    test('measures the way behind the flight against its estimate', () {
      final halfWay = flight(
        withRoute: route,
        tracking: FlightTracking(
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 1)),
          latestPosition: approaching(at: onFlightDay, longitude: -72),
        ),
      );

      final card = flightCardOf(halfWay, onFlightDay);

      expect(card.progressPercent, inInclusiveRange(1, 99));
    });

    test('has nothing to measure without an estimate', () {
      final card = flightCardOf(
        flight(departureTime: const DayTime(14, 30)),
        onFlightDay,
      );

      expect(card.progressPercent, isNull);
    });

    test('is full once the flight is down', () {
      final landed = flight(
        withRoute: route,
        tracking: FlightTracking(
          hasBeenAirborne: true,
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 8)),
          lastKnownOnGround: true,
          latestPosition: approaching(at: onFlightDay, onGround: true),
        ),
      );

      expect(flightCardOf(landed, onFlightDay).progressPercent, 100);
    });

    /// The bar is drawn once per put and never redrawn on its own, so a value
    /// past the estimate has to stop at the end rather than run over it.
    test('stops at full once the estimate has passed', () {
      final overdue = flight(
        withRoute: route,
        tracking: FlightTracking(
          firstAirborneAt: onFlightDay.subtract(const Duration(hours: 8)),
          latestPosition: approaching(
            at: onFlightDay.subtract(const Duration(minutes: 20)),
            longitude: -73.75,
          ),
        ),
      );

      expect(flightCardOf(overdue, onFlightDay).progressPercent, 100);
    });
  });

  test('marks an arrival the app could not confirm as uncertain', () {
    final stale = flight(
      withRoute: route,
      tracking: FlightTracking(
        firstAirborneAt: onFlightDay.subtract(const Duration(hours: 7)),
        latestPosition: approaching(
          at: onFlightDay.subtract(const Duration(minutes: 20)),
        ),
      ),
    );

    final card = flightCardOf(stale, onFlightDay);

    expect(card.state, FlightState.noSignal);
    expect(card.isArrivalUncertain, isTrue);
  });
}
