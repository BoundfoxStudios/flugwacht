import '../../domain/arrival_estimate.dart';
import '../../domain/departure_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_day_window.dart';
import '../../domain/flight_state.dart';

/// How long the card keeps its numbers after the moment they counted down to;
/// past that the data behind them is old enough to say so.
const liveActivityStaleGrace = Duration(minutes: 15);

/// What the widget extension needs to draw the flight, flat enough to travel
/// through the App Group as key-value pairs. Absent facts are left out rather
/// than sent as null.
Map<String, dynamic> liveActivityPayloadOf(Flight flight, DateTime now) {
  final route = flight.route;
  final tracking = flight.tracking;
  return {
    'designator': flight.lookupValue,
    if (flight.note case final note?) 'note': note,
    'state': resolveFlightState(flight, now).name,
    if (route != null) ...{
      'originCode': route.origin.iataCode ?? route.origin.icaoCode,
      'destinationCode':
          route.destination.iataCode ?? route.destination.icaoCode,
    },
    if (departureInstantOf(flight) case final departure?)
      'departureAt': departure.millisecondsSinceEpoch,
    if (arrivalEstimateOf(flight) case final estimate?)
      'estimatedArrivalAt': estimate.arrivesAt.millisecondsSinceEpoch,
    if (tracking.firstAirborneAt case final airborneAt?)
      'firstAirborneAt': airborneAt.millisecondsSinceEpoch,
    if (_landingOf(tracking) case final landedAt?)
      'landedAt': landedAt.millisecondsSinceEpoch,
  };
}

/// How long the card's numbers stay believable, measured from now because the
/// plugin takes a duration rather than a date.
Duration liveActivityStaleIn(Flight flight, DateTime now) {
  final target = _staleTarget(flight);
  // A moment that has already passed would dim the card the second it appears;
  // the flight day has to run out first.
  final honest = target != null && target.isAfter(now)
      ? target
      : FlightDayWindow.forDepartureDate(flight.departureDate).end;
  final remaining = honest.difference(now);
  return remaining.isNegative ? Duration.zero : remaining;
}

DateTime? _staleTarget(Flight flight) {
  final estimate = arrivalEstimateOf(flight);
  if (estimate != null) {
    return estimate.arrivesAt.add(liveActivityStaleGrace);
  }
  return departureInstantOf(flight)?.add(liveActivityStaleGrace);
}

DateTime? _landingOf(FlightTracking tracking) =>
    tracking.hasBeenAirborne && tracking.lastKnownOnGround == true
    ? tracking.latestPosition?.timestamp
    : null;
