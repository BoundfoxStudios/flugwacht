import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/day_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_route.dart';
import '../../domain/signal_age.dart';
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

/// Formats a time of day with a localized pattern; the date it is lifted onto
/// carries no meaning because the patterns only hold time fields.
String formatDayTime(BuildContext context, String pattern, DayTime time) =>
    DateFormat(
      pattern,
      Localizations.localeOf(context).toLanguageTag(),
    ).format(DateTime(2026, 1, 1, time.hour, time.minute));

/// How long ago the latest position came in, in the unit the breakdown holds.
String signalAgeLabel(AppLocalizations localizations, SignalAge age) =>
    switch (age) {
      SignalAgeSeconds(:final seconds) => localizations.mapSheetSignalSeconds(
        '$seconds',
      ),
      SignalAgeMinutes(:final minutes) => localizations.mapSheetSignalMinutes(
        '$minutes',
      ),
      SignalAgeHours(:final hours, :final minutes) =>
        minutes == 0
            ? localizations.mapSheetSignalHours('$hours')
            : localizations.mapSheetSignalHoursMinutes('$hours', '$minutes'),
    };
