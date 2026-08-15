import 'calendar_date.dart';
import 'fix.dart';
import 'flight_day_window.dart';
import 'flight_route.dart';

enum FlightLookupKind { flightNumber, registration, hexAddress }

class Flight {
  const Flight({
    required this.id,
    required this.lookupKind,
    required this.lookupValue,
    required this.departureDate,
    this.note,
    this.hexAddress,
    this.expectedCallsign,
    this.route,
    this.tracking = const FlightTracking(),
  });

  final int id;
  final FlightLookupKind lookupKind;
  final String lookupValue;
  final CalendarDate departureDate;
  final String? note;
  final String? hexAddress;
  final String? expectedCallsign;
  final FlightRoute? route;
  final FlightTracking tracking;

  Flight copyWith({
    int? id,
    FlightLookupKind? lookupKind,
    String? lookupValue,
    CalendarDate? departureDate,
    String? note,
    String? hexAddress,
    String? expectedCallsign,
    FlightRoute? route,
    FlightTracking? tracking,
  }) => Flight(
    id: id ?? this.id,
    lookupKind: lookupKind ?? this.lookupKind,
    lookupValue: lookupValue ?? this.lookupValue,
    departureDate: departureDate ?? this.departureDate,
    note: note ?? this.note,
    hexAddress: hexAddress ?? this.hexAddress,
    expectedCallsign: expectedCallsign ?? this.expectedCallsign,
    route: route ?? this.route,
    tracking: tracking ?? this.tracking,
  );
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
