import 'package:flugwacht/domain/arrival_estimate.dart';
import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedAt = DateTime.utc(2026, 3, 17, 12);

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
    DateTime? timestamp,
  }) => FixPosition(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? fixedAt,
    onGround: onGround,
    groundSpeedKnots: groundSpeedKnots,
  );

  Flight flightWith({FlightRoute? route, FixPosition? position}) => Flight(
    id: 1,
    lookupKind: FlightLookupKind.flightNumber,
    lookupValue: 'LH400',
    departureDate: const CalendarDate(2026, 3, 17),
    route: route,
    tracking: FlightTracking(latestPosition: position),
  );

  group('great-circle distance', () {
    test('measures a degree along the equator', () {
      expect(
        greatCircleDistanceKilometers(0, 0, 0, 1),
        closeTo(111.195, 0.001),
      );
    });

    test('measures across the antimeridian, not around the globe', () {
      expect(
        greatCircleDistanceKilometers(0, 179.5, 0, -179.5),
        closeTo(111.195, 0.001),
      );
    });

    test('measures a degree of latitude at any longitude', () {
      expect(
        greatCircleDistanceKilometers(50, 8.5, 51, 8.5),
        closeTo(111.195, 0.001),
      );
    });
  });

  group('estimate validity', () {
    test('needs a resolved route', () {
      expect(arrivalEstimateOf(flightWith(position: positionAt(0, 0))), isNull);
    });

    test('needs a latest position', () {
      expect(arrivalEstimateOf(flightWith(route: routeTo(0, 1))), isNull);
    });

    test('has none while the aircraft is on the ground', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, onGround: true),
      );
      expect(arrivalEstimateOf(flight), isNull);
    });

    test('has none without a ground speed', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, groundSpeedKnots: null),
      );
      expect(arrivalEstimateOf(flight), isNull);
    });

    test('has none below the speed floor', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, groundSpeedKnots: 49.9),
      );
      expect(arrivalEstimateOf(flight), isNull);
    });

    test('has one at the speed floor', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, groundSpeedKnots: 50),
      );
      expect(arrivalEstimateOf(flight), isNotNull);
    });

    test('has one for a fix that carries no ground flag', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, onGround: null),
      );
      expect(arrivalEstimateOf(flight), isNotNull);
    });
  });

  group('estimated arrival', () {
    test('anchors on the fix timestamp, not on the wall clock', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0),
      );
      // 111.195 km at 100 kn (185.2 km/h) takes 36 min 1.5 s.
      expect(
        arrivalEstimateOf(flight)!.arrivesAt.difference(fixedAt).inSeconds,
        2161,
      );
    });

    test('reports the arrival in UTC for a local fix timestamp', () {
      final flight = flightWith(
        route: routeTo(0, 1),
        position: positionAt(0, 0, timestamp: DateTime(2026, 3, 17, 12)),
      );
      final arrivesAt = arrivalEstimateOf(flight)!.arrivesAt;
      expect(arrivesAt.isUtc, isTrue);
      expect(arrivesAt.difference(DateTime(2026, 3, 17, 12)).inSeconds, 2161);
    });

    test('arrives at the fix timestamp once it is over the airport', () {
      final flight = flightWith(
        route: routeTo(0, 0),
        position: positionAt(0, 0),
      );
      expect(arrivalEstimateOf(flight)!.arrivesAt, fixedAt);
    });

    test('never runs backwards for a position past the destination', () {
      final flight = flightWith(
        route: routeTo(0, 0),
        position: positionAt(0, -0.001),
      );
      final arrivesAt = arrivalEstimateOf(flight)!.arrivesAt;
      expect(arrivesAt.isAfter(fixedAt), isTrue);
      expect(
        arrivesAt.difference(fixedAt),
        lessThan(const Duration(minutes: 1)),
      );
    });
  });
}
