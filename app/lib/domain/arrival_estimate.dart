import 'dart:math';

import 'flight.dart';
import 'unit_conversion.dart';

const earthRadiusKilometers = 6371.0;
const _minimumGroundSpeedKnots = 50.0;

class ArrivalEstimate {
  const ArrivalEstimate({required this.arrivesAt});

  final DateTime arrivesAt;
}

/// When the flight reaches its destination at the speed of its latest fix.
///
/// Anchored on the fix timestamp instead of the wall clock, so a position that
/// stops coming in freezes its estimate. There is none without a route, on the
/// ground, or below a ground speed that still reads as taxiing.
ArrivalEstimate? arrivalEstimateOf(Flight flight) {
  final destination = flight.route?.destination;
  final position = flight.tracking.latestPosition;
  final groundSpeedKnots = position?.groundSpeedKnots;
  if (destination == null ||
      position == null ||
      position.onGround == true ||
      groundSpeedKnots == null ||
      groundSpeedKnots < _minimumGroundSpeedKnots) {
    return null;
  }
  final remainingKilometers = greatCircleDistanceKilometers(
    position.latitude,
    position.longitude,
    destination.latitude,
    destination.longitude,
  );
  final hours =
      remainingKilometers / (groundSpeedKnots * kilometersPerHourPerKnot);
  return ArrivalEstimate(
    arrivesAt: position.timestamp.toUtc().add(
      Duration(microseconds: (hours * Duration.microsecondsPerHour).round()),
    ),
  );
}

double greatCircleDistanceKilometers(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  final latitudeDelta = radians(endLatitude - startLatitude);
  final longitudeDelta = radians(endLongitude - startLongitude);
  final haversine =
      pow(sin(latitudeDelta / 2), 2) +
      cos(radians(startLatitude)) *
          cos(radians(endLatitude)) *
          pow(sin(longitudeDelta / 2), 2);
  return 2 * earthRadiusKilometers * asin(min(1, sqrt(haversine)));
}

double radians(double degrees) => degrees * pi / 180;
