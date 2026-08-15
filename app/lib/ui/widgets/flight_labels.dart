import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/airport_timezone.dart';
import '../../domain/arrival_estimate.dart';
import '../../domain/day_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_route.dart';
import '../../domain/flight_state.dart';
import '../../domain/remaining_time.dart';
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

/// Formats a time with a localized pattern, in the zone the value carries.
String formatTime(BuildContext context, String pattern, DateTime time) =>
    DateFormat(
      pattern,
      Localizations.localeOf(context).toLanguageTag(),
    ).format(time);

/// Formats a time of day with a localized pattern; the date it is lifted onto
/// carries no meaning because the patterns only hold time fields.
String formatDayTime(BuildContext context, String pattern, DayTime time) =>
    formatTime(context, pattern, DateTime(2026, 1, 1, time.hour, time.minute));

/// The copy of the arrival block, shared by the sheet and the hero cell.
class ArrivalDisplay {
  const ArrivalDisplay({
    required this.label,
    required this.time,
    required this.detail,
    required this.localTime,
  });

  final String label;

  /// The arrival in the destination's local time, marked as frozen while the
  /// flight has no signal.
  final String time;

  /// What is left of the flight, or how old the frozen arrival is.
  final String detail;

  final String localTime;
}

/// The arrival the way both the sheet and the hero cell word it, or nothing
/// while the flight carries no estimate a viewer could act on.
ArrivalDisplay? arrivalDisplayOf(
  BuildContext context, {
  required Flight flight,
  required FlightState state,
  required DateTime now,
}) {
  final isLive = state == FlightState.live;
  final destination = flight.route?.destination;
  final position = flight.tracking.latestPosition;
  final estimate = arrivalEstimateOf(flight);
  if (!isLive && state != FlightState.noSignal ||
      destination == null ||
      position == null ||
      estimate == null) {
    return null;
  }
  final localArrival = airportLocalTime(destination, estimate.arrivesAt);
  if (localArrival == null) {
    return null;
  }
  final localizations = AppLocalizations.of(context);
  final pattern = localizations.flightArrivalTimeFormat;
  final time = formatTime(context, pattern, localArrival);
  return ArrivalDisplay(
    label: localizations.flightArrivalLabel,
    time: isLive ? time : localizations.flightArrivalFrozenTime(time),
    detail: isLive
        ? remainingTimeLabel(
            localizations,
            remainingTimeOf(estimate.arrivesAt.difference(now)),
          )
        : localizations.flightArrivalAsOf(
            signalAgeLabel(
              localizations,
              signalAgeOf(now.difference(position.timestamp)),
            ),
          ),
    localTime: localizations.flightArrivalLocalTime(
      destination.location ?? destination.name,
      formatTime(context, pattern, estimate.arrivesAt.toLocal()),
    ),
  );
}

/// How much of the flight is left, in the unit the breakdown holds.
String remainingTimeLabel(
  AppLocalizations localizations,
  RemainingTime remaining,
) => switch (remaining) {
  RemainingTimeMinutes(:final minutes) =>
    localizations.flightArrivalRemainingMinutes('$minutes'),
  RemainingTimeHours(:final hours, :final minutes) =>
    minutes == 0
        ? localizations.flightArrivalRemainingHours('$hours')
        : localizations.flightArrivalRemainingHoursMinutes(
            '$hours',
            '$minutes',
          ),
};

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
