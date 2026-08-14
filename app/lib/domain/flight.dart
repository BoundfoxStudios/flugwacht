import 'calendar_date.dart';
import 'fix.dart';
import 'flight_day_window.dart';

enum FlightLookupKind { flightNumber, registration, hexAddress }

class Flight {
  const Flight({
    required this.lookupKind,
    required this.lookupValue,
    required this.departureDate,
    this.note,
    this.hexAddress,
    this.expectedCallsign,
    this.tracking = const FlightTracking(),
  });

  final FlightLookupKind lookupKind;
  final String lookupValue;
  final CalendarDate departureDate;
  final String? note;
  final String? hexAddress;
  final String? expectedCallsign;
  final FlightTracking tracking;
}

class FlightTracking {
  const FlightTracking({
    this.latestPosition,
    this.hasBeenAirborne = false,
    this.lastKnownOnGround,
  });

  final FixPosition? latestPosition;
  final bool hasBeenAirborne;
  final bool? lastKnownOnGround;

  FlightTracking withFix(Fix fix, FlightDayWindow window) {
    final position = fix.position;
    if (position == null || position.timestamp.isBefore(window.start)) {
      return this;
    }
    return FlightTracking(
      latestPosition: position,
      hasBeenAirborne: hasBeenAirborne || position.onGround == false,
      lastKnownOnGround: position.onGround ?? lastKnownOnGround,
    );
  }
}
