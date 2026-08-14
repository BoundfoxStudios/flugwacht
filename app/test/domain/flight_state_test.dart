import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
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

  Flight flightWith(FlightTracking tracking) => Flight(
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH433',
    departureDate: departureDate,
    tracking: tracking,
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
}
