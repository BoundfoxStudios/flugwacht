import 'arrival_estimate.dart';
import 'departure_time.dart';
import 'flight.dart';
import 'flight_state.dart';

/// Which moment a card's countdown runs towards.
enum FlightCardCountdown { departure, arrival }

/// What a flight looks like on its card.
///
/// Resolved against a moment rather than left to the renderer: Android draws a
/// card once per put, so everything the iOS card works out while rendering has
/// to be decided here instead.
class FlightCard {
  const FlightCard({
    required this.designator,
    required this.state,
    required this.hasProbablyLanded,
    this.note,
    this.route,
    this.countdown,
    this.arrivesAt,
    this.landedAt,
    this.progressPercent,
  });

  final String designator;
  final FlightState state;

  /// The estimate ran out without the app seeing the aircraft on the ground.
  /// It can only see that while it runs, so the card says what it honestly
  /// knows rather than counting towards a moment that has passed.
  final bool hasProbablyLanded;

  final String? note;
  final ({String origin, String destination})? route;

  /// The moment the card counts towards, absent once nothing is left to count
  /// to. Always in the future: a countdown to a moment that has passed would
  /// start counting up.
  final ({FlightCardCountdown label, DateTime at})? countdown;

  /// The arrival the card still counts towards; a flight that is down has one
  /// in the past and shows its landing instead.
  final DateTime? arrivesAt;

  final DateTime? landedAt;

  /// How much of the way is behind the flight, absent while there is nothing
  /// to measure it against.
  final int? progressPercent;

  /// Whether the arrival time is a guess the app could not confirm.
  bool get isArrivalUncertain => state == FlightState.noSignal;
}

/// What the app knows about a flight, as its card shows it at [now].
FlightCard flightCardOf(Flight flight, DateTime now) {
  final state = resolveFlightState(flight, now);
  final route = flight.route;
  final arrivesAt = arrivalEstimateOf(flight)?.arrivesAt;
  final departsAt = departureInstantOf(flight);
  final isDown = state == FlightState.ended;
  final hasProbablyLanded =
      (state == FlightState.live || state == FlightState.noSignal) &&
      arrivesAt != null &&
      !arrivesAt.isAfter(now);
  return FlightCard(
    designator: flight.lookupValue,
    state: state,
    hasProbablyLanded: hasProbablyLanded,
    note: flight.note,
    route: route == null
        ? null
        : (
            origin: route.origin.iataCode ?? route.origin.icaoCode,
            destination:
                route.destination.iataCode ?? route.destination.icaoCode,
          ),
    countdown: _countdownOf(state, arrivesAt, departsAt, now),
    arrivesAt: isDown ? null : arrivesAt,
    landedAt: isDown ? _landingOf(flight.tracking) : null,
    // A flight that is down has flown all of its way, and has no estimate left
    // to measure it against.
    progressPercent: isDown
        ? 100
        : _progressPercentOf(flight, arrivesAt, departsAt, now),
  );
}

({FlightCardCountdown label, DateTime at})? _countdownOf(
  FlightState state,
  DateTime? arrivesAt,
  DateTime? departsAt,
  DateTime now,
) {
  final target = switch (state) {
    FlightState.live || FlightState.noSignal =>
      arrivesAt == null
          ? null
          : (label: FlightCardCountdown.arrival, at: arrivesAt),
    FlightState.planned || FlightState.waiting =>
      departsAt == null
          ? null
          : (label: FlightCardCountdown.departure, at: departsAt),
    FlightState.ended || FlightState.missed => null,
  };
  return target != null && target.at.isAfter(now) ? target : null;
}

/// The way behind the flight, anchored on the moment it left the ground; the
/// scheduled departure stands in until it did.
int? _progressPercentOf(
  Flight flight,
  DateTime? arrivesAt,
  DateTime? departsAt,
  DateTime now,
) {
  final start = flight.tracking.firstAirborneAt ?? departsAt;
  if (arrivesAt == null || start == null || !start.isBefore(arrivesAt)) {
    return null;
  }
  final total = arrivesAt.difference(start).inSeconds;
  final flown = now.difference(start).inSeconds;
  return (flown * 100 / total).round().clamp(0, 100);
}

DateTime? _landingOf(FlightTracking tracking) =>
    tracking.hasBeenAirborne && tracking.lastKnownOnGround == true
    ? tracking.latestPosition?.timestamp
    : null;
