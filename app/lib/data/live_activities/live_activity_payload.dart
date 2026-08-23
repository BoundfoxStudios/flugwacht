import '../../domain/arrival_estimate.dart';
import '../../domain/departure_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_day_window.dart';
import '../../domain/flight_state.dart';
import 'live_activity_url.dart';

/// How long the card keeps its numbers after the moment they counted down to.
///
/// Zero on purpose: the stale date is the one moment iOS re-evaluates a card
/// without the app, so it has to sit exactly where the card stops being true.
/// A grace period past the arrival would leave a finished countdown claiming
/// to be live for that much longer.
const liveActivityStaleGrace = Duration.zero;

/// The plugin sends the stale window as whole minutes and drops anything under
/// one, so a shorter window would leave the card claiming its numbers are
/// fresh forever.
const _shortestStaleWindow = Duration(minutes: 1);

/// What the widget extension needs to draw the flight, flat enough to travel
/// through the App Group as key-value pairs.
///
/// Every key travels on every payload: an update only clears what it carries
/// as null, a create would throw on one, and a key left out keeps whatever the
/// last update wrote. A fact that stops applying therefore has to arrive as an
/// empty string or a zero timestamp.
Map<String, dynamic> liveActivityPayloadOf(Flight flight, DateTime now) {
  final route = flight.route;
  final tracking = flight.tracking;
  return {
    'url': liveActivityUrlOf(flight.id),
    'designator': flight.lookupValue,
    'note': flight.note ?? '',
    'state': resolveFlightState(flight, now).name,
    'originCode': route == null
        ? ''
        : route.origin.iataCode ?? route.origin.icaoCode,
    'destinationCode': route == null
        ? ''
        : route.destination.iataCode ?? route.destination.icaoCode,
    'departureAt': _epochOf(departureInstantOf(flight)),
    'estimatedArrivalAt': _epochOf(arrivalEstimateOf(flight)?.arrivesAt),
    'firstAirborneAt': _epochOf(tracking.firstAirborneAt),
    'landedAt': _epochOf(_landingOf(tracking)),
  };
}

/// How long the card's numbers stay believable, measured from now because the
/// plugin takes a duration rather than a date.
Duration liveActivityStaleIn(Flight flight, DateTime now) {
  // Without a target at all the flight day has to run out first; a target that
  // has already passed is exactly what staleness is for, so it falls through
  // to the floor below and the card says so right away.
  final target =
      _staleTarget(flight) ??
      FlightDayWindow.forDepartureDate(flight.departureDate).end;
  final remaining = target.difference(now);
  return remaining < _shortestStaleWindow ? _shortestStaleWindow : remaining;
}

/// Which card the Dynamic Island shows and how the cards stack on the Lock
/// Screen: iOS picks the highest score, and a flight in the air has more to
/// show than one that has not left yet.
double liveActivityRelevanceOf(Flight flight, DateTime now) =>
    switch (resolveFlightState(flight, now)) {
      FlightState.live => 3,
      FlightState.noSignal => 2,
      FlightState.waiting => 1,
      // A landed card is only still up to be looked at. The other two never
      // reach ActivityKit at all: planLiveActivityAction keeps no card for a
      // flight outside its flight day, and takes a running one down without a
      // last put.
      FlightState.ended || FlightState.planned || FlightState.missed => 0,
    };

int _epochOf(DateTime? instant) => instant?.millisecondsSinceEpoch ?? 0;

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
