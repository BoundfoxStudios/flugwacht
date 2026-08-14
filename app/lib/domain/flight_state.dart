import 'flight.dart';
import 'flight_day_window.dart';

enum FlightState { planned, waiting, live, noSignal, ended, missed }

const maximumLivePositionAge = Duration(minutes: 15);

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
  if (tracking.hasBeenAirborne && tracking.lastKnownOnGround == true) {
    return FlightState.ended;
  }
  if (seenPosition == null) {
    return FlightState.waiting;
  }
  return now.difference(seenPosition.timestamp) <= maximumLivePositionAge
      ? FlightState.live
      : FlightState.noSignal;
}
