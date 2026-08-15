import '../../domain/flight.dart';
import '../../domain/flight_state.dart';

class FlightListEntry {
  const FlightListEntry({required this.flight, required this.state});

  final Flight flight;
  final FlightState state;
}

class FlightListSections {
  const FlightListSections({
    required this.active,
    required this.waiting,
    required this.planned,
    required this.past,
  });

  final List<FlightListEntry> active;
  final List<FlightListEntry> waiting;
  final List<FlightListEntry> planned;
  final List<FlightListEntry> past;

  bool get isEmpty =>
      active.isEmpty && waiting.isEmpty && planned.isEmpty && past.isEmpty;
}

/// Splits the stored flights into the sections of the list screen, keeping the
/// incoming order inside every section and leaving out expired flights.
FlightListSections groupFlights(List<Flight> flights, DateTime now) {
  final active = <FlightListEntry>[];
  final waiting = <FlightListEntry>[];
  final planned = <FlightListEntry>[];
  final past = <FlightListEntry>[];
  for (final flight in flights) {
    if (hasFlightExpired(flight, now)) {
      continue;
    }
    final state = resolveFlightState(flight, now);
    final entry = FlightListEntry(flight: flight, state: state);
    switch (state) {
      case FlightState.live || FlightState.noSignal:
        active.add(entry);
      case FlightState.waiting:
        waiting.add(entry);
      case FlightState.planned:
        planned.add(entry);
      case FlightState.ended || FlightState.missed:
        past.add(entry);
    }
  }
  return FlightListSections(
    active: active,
    waiting: waiting,
    planned: planned,
    past: past,
  );
}
