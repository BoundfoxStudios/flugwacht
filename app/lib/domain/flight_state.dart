import 'flight.dart';
import 'flight_day_window.dart';

enum FlightState { planned, waiting, live, noSignal, ended, missed }

const maximumLivePositionAge = Duration(minutes: 15);

const pastFlightRetention = Duration(hours: 24);

FlightState resolveFlightState(Flight flight, DateTime now) {
  final window = FlightDayWindow.forDepartureDate(flight.departureDate);
  if (now.isBefore(window.start)) {
    return FlightState.planned;
  }

  final tracking = flight.tracking;
  final latestPosition = tracking.latestPosition;
  final seenPosition =
      latestPosition != null && !latestPosition.timestamp.isBefore(window.start)
      ? latestPosition
      : null;

  if (!window.contains(now)) {
    return seenPosition == null ? FlightState.missed : FlightState.ended;
  }
  if (isOnGroundAfterFlying(tracking)) {
    return FlightState.ended;
  }
  if (seenPosition == null) {
    return FlightState.waiting;
  }
  return now.difference(seenPosition.timestamp) <= maximumLivePositionAge
      ? FlightState.live
      : FlightState.noSignal;
}

bool isOnGroundAfterFlying(FlightTracking tracking) =>
    tracking.hasBeenAirborne && tracking.lastKnownOnGround == true;

bool hasFlightExpired(Flight flight, DateTime now) =>
    !now.isBefore(_expiryReference(flight).add(pastFlightRetention));

DateTime _expiryReference(Flight flight) {
  final window = FlightDayWindow.forDepartureDate(flight.departureDate);
  final tracking = flight.tracking;
  final latestPosition = tracking.latestPosition;
  if (latestPosition != null &&
      isOnGroundAfterFlying(tracking) &&
      window.contains(latestPosition.timestamp)) {
    return latestPosition.timestamp;
  }
  return window.end;
}
