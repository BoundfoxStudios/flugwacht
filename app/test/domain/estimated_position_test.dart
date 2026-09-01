import 'package:flugwacht/domain/arrival_estimate.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/estimated_position.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedAt = DateTime.utc(2026, 3, 17, 12);
  final withoutSignalAt = fixedAt.add(const Duration(minutes: 30));

  RouteAirport airportAt(double latitude, double longitude) => RouteAirport(
    icaoCode: 'KJFK',
    name: 'John F. Kennedy',
    latitude: latitude,
    longitude: longitude,
  );

  FlightRoute routeTo(double latitude, double longitude) => FlightRoute(
    origin: airportAt(50.0379, 8.5622),
    destination: airportAt(latitude, longitude),
  );

  FixPosition positionAt(
    double latitude,
    double longitude, {
    double? groundSpeedKnots = 100,
    bool? onGround = false,
  }) => FixPosition(
    latitude: latitude,
    longitude: longitude,
    timestamp: fixedAt,
    onGround: onGround,
    groundSpeedKnots: groundSpeedKnots,
  );

  Flight flightWith({
    FlightRoute? route,
    FixPosition? position,
    bool hasBeenAirborne = true,
  }) => Flight(
    id: 1,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH400',
    departureDate: const CalendarDate(2026, 3, 17),
    route: route,
    tracking: FlightTracking(
      latestPosition: position,
      hasBeenAirborne: hasBeenAirborne,
    ),
  );

  Flight alongTheEquator() =>
      flightWith(route: routeTo(0, 1), position: positionAt(0, 0));

  DateTime arrivalOf(Flight flight) => arrivalEstimateOf(flight)!.arrivesAt;

  DateTime halfwayTo(Flight flight) =>
      fixedAt.add(arrivalOf(flight).difference(fixedAt) ~/ 2);

  group('estimate validity', () {
    test('has none while the flight is live', () {
      final now = fixedAt.add(const Duration(seconds: 3));
      expect(estimatedPositionOf(alongTheEquator(), now), isNull);
    });

    test('has none without a route', () {
      final flight = flightWith(position: positionAt(0, 0));
      expect(estimatedPositionOf(flight, withoutSignalAt), isNull);
    });

    test('has none for a flight never seen airborne', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0),
        hasBeenAirborne: false,
      );
      expect(estimatedPositionOf(flight, withoutSignalAt), isNull);
    });

    test('has none on the ground', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, onGround: true),
      );
      expect(estimatedPositionOf(flight, withoutSignalAt), isNull);
    });

    test('has none below the speed floor', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, groundSpeedKnots: 49.9),
      );
      expect(estimatedPositionOf(flight, withoutSignalAt), isNull);
    });

    test('has none once the arrival has passed', () {
      final flight = alongTheEquator();
      expect(estimatedPositionOf(flight, arrivalOf(flight)), isNull);
    });
  });

  group('estimated point', () {
    test('walks half the great circle at half the time', () {
      final flight = alongTheEquator();
      final estimated = estimatedPositionOf(flight, halfwayTo(flight))!;
      expect(estimated.longitude, closeTo(0.5, 1e-6));
      expect(estimated.latitude, closeTo(0, 1e-9));
      expect(estimated.trackDegrees, closeTo(90, 1e-6));
    });

    test('heads along the meridian', () {
      final flight = flightWith(
        route: routeTo(1, 0),
        position: positionAt(0, 0),
      );
      final estimated = estimatedPositionOf(flight, halfwayTo(flight))!;
      expect(estimated.latitude, closeTo(0.5, 1e-6));
      expect(estimated.trackDegrees, closeTo(0, 1e-6));
    });

    test('sits beside the destination just before the arrival', () {
      final flight = alongTheEquator();
      final now = arrivalOf(flight).subtract(const Duration(seconds: 1));
      final estimated = estimatedPositionOf(flight, now)!;
      expect(estimated.latitude, closeTo(0, 0.001));
      expect(estimated.longitude, closeTo(1, 0.001));
    });

    test('wraps the longitude across the antimeridian', () {
      final flight = flightWith(
        route: routeTo(0, -177),
        position: positionAt(0, 179),
      );
      final estimated = estimatedPositionOf(flight, halfwayTo(flight))!;
      expect(estimated.longitude, closeTo(-179, 1e-6));
    });

    test('anchors on the fix, not on the clock', () {
      final flight = alongTheEquator();
      final now = fixedAt.add(const Duration(minutes: 20));
      // 20 min at 100 kn (185.2 km/h) covers 61.73 km, 0.5552 degrees east.
      expect(
        estimatedPositionOf(flight, now)!.longitude,
        closeTo(0.5552, 0.0001),
      );
    });
  });
}
