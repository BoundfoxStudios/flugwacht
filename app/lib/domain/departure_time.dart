import 'airport_timezone.dart';
import 'flight.dart';

/// The instant the stored departure wall clock names, or nothing while the
/// flight has no departure time.
///
/// An origin-local reading without a route or a resolvable zone falls back to
/// the device clock, mirroring what the new-flight form stores in that case.
DateTime? departureInstantOf(Flight flight) {
  final departureTime = flight.departureTime;
  if (departureTime == null) {
    return null;
  }
  final date = flight.departureDate;
  if (flight.departureTimeInterpretation ==
      DepartureTimeInterpretation.originLocal) {
    final origin = flight.route?.origin;
    final instant = origin == null
        ? null
        : airportInstantOf(origin, date, departureTime);
    if (instant != null) {
      return instant;
    }
  }
  return DateTime(
    date.year,
    date.month,
    date.day,
    departureTime.hour,
    departureTime.minute,
  );
}
