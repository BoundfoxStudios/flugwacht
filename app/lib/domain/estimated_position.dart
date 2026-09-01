import 'dart:math';

import 'arrival_estimate.dart';
import 'flight.dart';
import 'flight_state.dart';

class EstimatedPosition {
  const EstimatedPosition({
    required this.latitude,
    required this.longitude,
    required this.trackDegrees,
  });

  final double latitude;
  final double longitude;
  final double trackDegrees;
}

/// Where the aircraft would be by now had it kept the ground speed of its
/// last fix towards the destination: the arrival estimate read in space.
/// Only while the flight has no signal and was seen airborne; null otherwise.
EstimatedPosition? estimatedPositionOf(Flight flight, DateTime now) {
  final destination = flight.route?.destination;
  final position = flight.tracking.latestPosition;
  final arrivesAt = arrivalEstimateOf(flight)?.arrivesAt;
  if (destination == null ||
      position == null ||
      arrivesAt == null ||
      !flight.tracking.hasBeenAirborne ||
      !now.isBefore(arrivesAt) ||
      resolveFlightState(flight, now) != FlightState.noSignal) {
    return null;
  }
  final total = arrivesAt.difference(position.timestamp);
  if (total <= Duration.zero) {
    return null;
  }
  final fraction =
      now.difference(position.timestamp).inMicroseconds / total.inMicroseconds;
  final startLatitude = radians(position.latitude);
  final startLongitude = radians(position.longitude);
  final endLatitude = radians(destination.latitude);
  final endLongitude = radians(destination.longitude);
  final bearing = _initialBearing(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );
  final angularDistance =
      fraction *
      greatCircleDistanceKilometers(
        position.latitude,
        position.longitude,
        destination.latitude,
        destination.longitude,
      ) /
      earthRadiusKilometers;
  final latitude = asin(
    sin(startLatitude) * cos(angularDistance) +
        cos(startLatitude) * sin(angularDistance) * cos(bearing),
  );
  final longitude =
      startLongitude +
      atan2(
        sin(bearing) * sin(angularDistance) * cos(startLatitude),
        cos(angularDistance) - sin(startLatitude) * sin(latitude),
      );
  return EstimatedPosition(
    latitude: _degrees(latitude),
    longitude: (_degrees(longitude) + 180) % 360 - 180,
    trackDegrees:
        _degrees(
          _initialBearing(latitude, longitude, endLatitude, endLongitude),
        ) %
        360,
  );
}

double _initialBearing(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  final longitudeDelta = endLongitude - startLongitude;
  return atan2(
    sin(longitudeDelta) * cos(endLatitude),
    cos(startLatitude) * sin(endLatitude) -
        sin(startLatitude) * cos(endLatitude) * cos(longitudeDelta),
  );
}

double _degrees(double angle) => angle * 180 / pi;
