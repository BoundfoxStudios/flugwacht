import 'arrival_estimate.dart';
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
  if (now.difference(seenPosition.timestamp) <= maximumLivePositionAge) {
    return FlightState.live;
  }
  final probableLandingAt = probableLandingOf(flight);
  return probableLandingAt != null && !now.isBefore(probableLandingAt)
      ? FlightState.ended
      : FlightState.noSignal;
}

bool isOnGroundAfterFlying(FlightTracking tracking) =>
    tracking.hasBeenAirborne && tracking.lastKnownOnGround == true;

/// When the app saw the aircraft on the ground after it had flown, which is
/// the only landing it can witness. An ended flight without one is down by
/// inference rather than by observation.
DateTime? landingTimeOf(FlightTracking tracking) =>
    isOnGroundAfterFlying(tracking) ? tracking.latestPosition?.timestamp : null;

/// The arrival the flight's last fix pointed at, from which a flight nobody
/// watched land counts as down.
///
/// A landing only shows up as a fix from the ground, and that fix exists for
/// the few minutes the aircraft still transmits while it rolls. The app polls
/// in the foreground alone and the sources keep no history to ask afterwards,
/// so a flight that lands while nobody watches would otherwise sit without
/// signal until its flight day runs out (#307). The estimate is frozen on the
/// last fix, so the moment stands still while the clock walks past it.
DateTime? probableLandingOf(Flight flight) => flight.tracking.hasBeenAirborne
    ? arrivalEstimateOf(flight)?.arrivesAt
    : null;

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
