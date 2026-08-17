import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as timezone_map;
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart';

import 'calendar_date.dart';
import 'day_time.dart';
import 'flight_route.dart';

var _isDatabaseLoaded = false;

/// Loads the time zone database, so the first conversion does not pay for it
/// during a frame. Calling it again is free.
void initializeAirportTimezones() {
  if (_isDatabaseLoaded) {
    return;
  }
  timezone_data.initializeTimeZones();
  _isDatabaseLoaded = true;
}

/// The instant in the airport's local time, or nothing when the database does
/// not carry the zone its coordinates fall into.
///
/// The full database variant is the one that carries every zone the coordinate
/// lookup can name — the reduced variants drop the linked zones and would lose
/// destinations like Amsterdam or Oslo.
TZDateTime? airportLocalTime(RouteAirport airport, DateTime instant) {
  initializeAirportTimezones();
  final zone = timezone_map.latLngToTimezoneString(
    airport.latitude,
    airport.longitude,
  );
  try {
    return TZDateTime.from(instant, getLocation(zone));
  } on LocationNotFoundException {
    return null;
  }
}

/// The instant a wall-clock reading in the airport's local time names, as UTC,
/// or nothing when the database does not carry the airport's zone.
DateTime? airportInstantOf(
  RouteAirport airport,
  CalendarDate date,
  DayTime time,
) {
  initializeAirportTimezones();
  final zone = timezone_map.latLngToTimezoneString(
    airport.latitude,
    airport.longitude,
  );
  try {
    final wallClock = TZDateTime(
      getLocation(zone),
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    // A plain DateTime, not the TZDateTime: its toLocal converts to the
    // package's own local location instead of the device zone.
    return DateTime.fromMillisecondsSinceEpoch(
      wallClock.millisecondsSinceEpoch,
      isUtc: true,
    );
  } on LocationNotFoundException {
    return null;
  }
}
