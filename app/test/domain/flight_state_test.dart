import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const departureDate = CalendarDate(2026, 3, 17);
  final window = FlightDayWindow.forDepartureDate(departureDate);

  Fix positionFix(DateTime timestamp, {bool? onGround}) => Fix(
    hexAddress: '3c64c6',
    sourceId: SourceId.adsblol,
    position: FixPosition(
      latitude: 49.875687,
      longitude: 7.888834,
      timestamp: timestamp,
      onGround: onGround,
    ),
  );

  FlightTracking trackingFrom(List<Fix> fixes) => fixes.fold(
    const FlightTracking(),
    (tracking, fix) => tracking.withFix(fix, window),
  );

  DateTime afterWindowStart(Duration offset) =>
      window.start.add(offset).toUtc();

  Flight flightWith(FlightTracking tracking, {FlightRoute? route}) => Flight(
    id: 1,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH433',
    departureDate: departureDate,
    route: route,
    tracking: tracking,
  );

  const homeRoute = FlightRoute(
    origin: RouteAirport(
      icaoCode: 'LEPA',
      iataCode: 'PMI',
      name: 'Palma de Mallorca',
      latitude: 39.5517,
      longitude: 2.73881,
    ),
    destination: RouteAirport(
      icaoCode: 'EDDF',
      iataCode: 'FRA',
      name: 'Frankfurt am Main',
      latitude: 50.0379,
      longitude: 8.5622,
    ),
  );

  /// A last fix on the way to Frankfurt at cruise speed: fifty kilometres out
  /// it points at an arrival minutes away, six hundred at one an hour off.
  FlightTracking headingHome(
    DateTime at, {
    double longitude = 7.888834,
    bool hasBeenAirborne = true,
    bool? onGround = false,
  }) => FlightTracking(
    hasBeenAirborne: hasBeenAirborne,
    latestPosition: FixPosition(
      latitude: 49.875687,
      longitude: longitude,
      timestamp: at,
      onGround: onGround,
      groundSpeedKnots: 400,
    ),
  );

  test('is planned before the window starts', () {
    final now = window.start.subtract(const Duration(minutes: 1));
    expect(
      resolveFlightState(flightWith(const FlightTracking()), now),
      FlightState.planned,
    );
  });

  test('is no longer planned exactly at the window start', () {
    expect(
      resolveFlightState(flightWith(const FlightTracking()), window.start),
      FlightState.waiting,
    );
  });

  test('is waiting for a flight added in the middle of its flight day', () {
    final now = window.start.add(const Duration(hours: 5));
    expect(
      resolveFlightState(flightWith(const FlightTracking()), now),
      FlightState.waiting,
    );
  });

  test(
    'is live while the latest position is within the freshness threshold',
    () {
      final now = window.start.add(const Duration(hours: 5));
      final tracking = trackingFrom([
        positionFix(
          now.subtract(maximumLivePositionAge).toUtc(),
          onGround: false,
        ),
      ]);
      expect(resolveFlightState(flightWith(tracking), now), FlightState.live);
    },
  );

  test('has no signal once the latest position exceeds the threshold', () {
    final now = window.start.add(const Duration(hours: 5));
    final tracking = trackingFrom([
      positionFix(
        now
            .subtract(maximumLivePositionAge)
            .subtract(const Duration(microseconds: 1))
            .toUtc(),
        onGround: false,
      ),
    ]);
    expect(resolveFlightState(flightWith(tracking), now), FlightState.noSignal);
  });

  test('ends a silent flight past the arrival its last fix pointed at', () {
    final now = window.start.add(const Duration(hours: 5));
    final flight = flightWith(
      headingHome(now.subtract(const Duration(hours: 1)).toUtc()),
      route: homeRoute,
    );
    expect(resolveFlightState(flight, now), FlightState.ended);
  });

  test('stays without signal while that arrival is still ahead', () {
    final now = window.start.add(const Duration(hours: 5));
    final flight = flightWith(
      headingHome(
        now.subtract(const Duration(minutes: 20)).toUtc(),
        longitude: 0,
      ),
      route: homeRoute,
    );
    expect(resolveFlightState(flight, now), FlightState.noSignal);
  });

  test('stays without signal for a flight with no arrival to point at', () {
    final now = window.start.add(const Duration(hours: 5));
    final flight = flightWith(
      headingHome(now.subtract(const Duration(hours: 1)).toUtc()),
    );
    expect(resolveFlightState(flight, now), FlightState.noSignal);
  });

  test('ends nothing that was never seen off the ground', () {
    final now = window.start.add(const Duration(hours: 5));
    final flight = flightWith(
      headingHome(
        now.subtract(const Duration(hours: 1)).toUtc(),
        hasBeenAirborne: false,
        onGround: null,
      ),
      route: homeRoute,
    );
    expect(resolveFlightState(flight, now), FlightState.noSignal);
  });

  test('counts a position timestamped in the future as fresh', () {
    final now = window.start.add(const Duration(hours: 5));
    final tracking = trackingFrom([
      positionFix(now.add(const Duration(minutes: 2)).toUtc(), onGround: false),
    ]);
    expect(resolveFlightState(flightWith(tracking), now), FlightState.live);
  });

  test('ends the flight as soon as an airborne flight is back on ground', () {
    final now = window.start.add(const Duration(hours: 9));
    final tracking = trackingFrom([
      positionFix(
        window.start.add(const Duration(hours: 2)).toUtc(),
        onGround: false,
      ),
      positionFix(now.toUtc(), onGround: true),
    ]);
    expect(resolveFlightState(flightWith(tracking), now), FlightState.ended);
  });

  test('stays live on the ground before ever being airborne', () {
    final now = window.start.add(const Duration(hours: 2));
    final tracking = trackingFrom([positionFix(now.toUtc(), onGround: true)]);
    expect(resolveFlightState(flightWith(tracking), now), FlightState.live);
  });

  test('returns to live when an airborne fix follows a ground fix', () {
    final now = window.start.add(const Duration(hours: 4));
    final tracking = trackingFrom([
      positionFix(
        window.start.add(const Duration(hours: 2)).toUtc(),
        onGround: false,
      ),
      positionFix(
        window.start.add(const Duration(hours: 3)).toUtc(),
        onGround: true,
      ),
      positionFix(now.toUtc(), onGround: false),
    ]);
    expect(resolveFlightState(flightWith(tracking), now), FlightState.live);
  });

  test('is ended exactly at the window end when a position was received', () {
    final tracking = trackingFrom([
      positionFix(
        window.start.add(const Duration(hours: 2)).toUtc(),
        onGround: false,
      ),
    ]);
    expect(
      resolveFlightState(flightWith(tracking), window.end),
      FlightState.ended,
    );
  });

  test('is missed exactly at the window end without any position', () {
    expect(
      resolveFlightState(flightWith(const FlightTracking()), window.end),
      FlightState.missed,
    );
  });

  test('is missed for a flight whose departure date has passed', () {
    final now = window.end.add(const Duration(days: 3));
    expect(
      resolveFlightState(flightWith(const FlightTracking()), now),
      FlightState.missed,
    );
  });

  test('ignores a position from before the window while it is running', () {
    final now = window.start.add(const Duration(hours: 5));
    final tracking = FlightTracking(
      latestPosition: positionFix(
        window.start.subtract(const Duration(minutes: 30)).toUtc(),
        onGround: false,
      ).position,
    );
    expect(resolveFlightState(flightWith(tracking), now), FlightState.waiting);
  });

  test('ignores a position from before the window after it has ended', () {
    final tracking = FlightTracking(
      latestPosition: positionFix(
        window.start.subtract(const Duration(minutes: 30)).toUtc(),
        onGround: false,
      ).position,
    );
    expect(
      resolveFlightState(flightWith(tracking), window.end),
      FlightState.missed,
    );
  });

  test('keeps a missed flight until 24 h after the window end', () {
    final flight = flightWith(const FlightTracking());
    final expiry = window.end.add(const Duration(hours: 24));

    expect(
      hasFlightExpired(flight, expiry.subtract(const Duration(minutes: 1))),
      isFalse,
    );
    expect(hasFlightExpired(flight, expiry), isTrue);
  });

  test('expires a flight that ran to the window end 24 h later', () {
    final flight = flightWith(
      trackingFrom([
        positionFix(
          afterWindowStart(const Duration(hours: 2)),
          onGround: false,
        ),
      ]),
    );
    final expiry = window.end.add(pastFlightRetention);

    expect(
      hasFlightExpired(flight, expiry.subtract(const Duration(minutes: 1))),
      isFalse,
    );
    expect(hasFlightExpired(flight, expiry), isTrue);
  });

  test('expires an early landed flight while its window is still open', () {
    final landing = afterWindowStart(const Duration(hours: 2));
    final flight = flightWith(
      trackingFrom([
        positionFix(
          afterWindowStart(const Duration(hours: 1)),
          onGround: false,
        ),
        positionFix(landing, onGround: true),
      ]),
    );
    final expiry = landing.add(pastFlightRetention);

    expect(window.contains(expiry), isTrue);
    expect(
      hasFlightExpired(flight, expiry.subtract(const Duration(minutes: 1))),
      isFalse,
    );
    expect(hasFlightExpired(flight, expiry), isTrue);
  });

  test('never expires a flight whose window is still running', () {
    final flight = flightWith(
      trackingFrom([
        positionFix(
          afterWindowStart(const Duration(hours: 1)),
          onGround: false,
        ),
      ]),
    );

    expect(
      hasFlightExpired(flight, window.end.subtract(const Duration(minutes: 1))),
      isFalse,
    );
  });

  test('stops expiring early once the flight takes off again', () {
    final landing = afterWindowStart(const Duration(hours: 2));
    final flight = flightWith(
      trackingFrom([
        positionFix(
          afterWindowStart(const Duration(hours: 1)),
          onGround: false,
        ),
        positionFix(landing, onGround: true),
        positionFix(
          afterWindowStart(const Duration(hours: 3)),
          onGround: false,
        ),
      ]),
    );

    expect(hasFlightExpired(flight, landing.add(pastFlightRetention)), isFalse);
  });

  test('never expires a flight that has only been seen on the ground', () {
    final parked = afterWindowStart(const Duration(hours: 1));
    final flight = flightWith(
      trackingFrom([positionFix(parked, onGround: true)]),
    );

    expect(flight.tracking.hasBeenAirborne, isFalse);
    expect(window.contains(parked.add(pastFlightRetention)), isTrue);
    expect(hasFlightExpired(flight, parked.add(pastFlightRetention)), isFalse);
  });

  test('falls back to the window end for a landing after the window', () {
    final landing = window.end.add(const Duration(hours: 3)).toUtc();
    final flight = flightWith(
      trackingFrom([
        positionFix(
          afterWindowStart(const Duration(hours: 1)),
          onGround: false,
        ),
        positionFix(landing, onGround: true),
      ]),
    );

    expect(
      hasFlightExpired(flight, window.end.add(pastFlightRetention)),
      isTrue,
    );
  });

  test('falls back to the window end for a landing before the window', () {
    final flight = flightWith(
      FlightTracking(
        latestPosition: positionFix(
          window.start.subtract(const Duration(hours: 1)).toUtc(),
          onGround: true,
        ).position,
        hasBeenAirborne: true,
        lastKnownOnGround: true,
      ),
    );

    expect(hasFlightExpired(flight, window.start), isFalse);
  });
}
