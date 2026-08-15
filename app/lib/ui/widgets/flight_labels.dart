import '../../domain/flight.dart';
import '../../domain/flight_route.dart';
import '../../l10n/app_localizations.g.dart';

/// The lookup value with the note appended, the way both the list rows and the
/// hero cell head a flight.
String flightTitle(AppLocalizations localizations, Flight flight) {
  final note = flight.note;
  return note == null
      ? flight.lookupValue
      : localizations.flightTitleWithNote(flight.lookupValue, note);
}

/// The route in IATA codes, falling back to ICAO for an airport without one.
String? flightRouteLabel(AppLocalizations localizations, FlightRoute? route) =>
    route == null
    ? null
    : localizations.flightRoute(
        route.origin.iataCode ?? route.origin.icaoCode,
        route.destination.iataCode ?? route.destination.icaoCode,
      );
