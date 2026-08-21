import 'package:drift/drift.dart';

import '../../domain/calendar_date.dart';
import '../../domain/day_time.dart';
import '../../domain/fix.dart';
import '../../domain/flight.dart';
import '../../domain/flight_notification.dart';
import '../../domain/flight_route.dart';
import '../../domain/flight_state.dart';
import '../../domain/source_id.dart';
import '../../domain/trail_point.dart';
import 'database.dart';

class FlightRepository {
  FlightRepository(this._database);

  final AppDatabase _database;

  Stream<List<Flight>> watchFlights() {
    final query = _database.select(_database.flights)
      ..orderBy([
        (row) => OrderingTerm(expression: row.departureDate),
        (row) => OrderingTerm(expression: row.id),
      ]);
    return query.watch().map((rows) => rows.map(_toFlight).toList());
  }

  Future<Flight> addFlight({
    required FlightLookupKind lookupKind,
    required String lookupValue,
    required CalendarDate departureDate,
    DayTime? departureTime,
    DepartureTimeInterpretation departureTimeInterpretation =
        DepartureTimeInterpretation.device,
    String? note,
    String? hexAddress,
    String? expectedCallsign,
    FlightRoute? route,
  }) async {
    final row = await _database
        .into(_database.flights)
        .insertReturning(
          FlightsCompanion.insert(
            lookupKind: lookupKind,
            lookupValue: lookupValue,
            departureDate: _toIsoDate(departureDate),
            departureMinutesSinceMidnight: Value(
              departureTime?.minutesSinceMidnight,
            ),
            departureTimeInterpretation: departureTimeInterpretation,
            note: Value(note),
            hexAddress: Value(hexAddress),
            expectedCallsign: Value(expectedCallsign),
            originIcaoCode: Value(route?.origin.icaoCode),
            originIataCode: Value(route?.origin.iataCode),
            originName: Value(route?.origin.name),
            originLocation: Value(route?.origin.location),
            originLatitude: Value(route?.origin.latitude),
            originLongitude: Value(route?.origin.longitude),
            destinationIcaoCode: Value(route?.destination.icaoCode),
            destinationIataCode: Value(route?.destination.iataCode),
            destinationName: Value(route?.destination.name),
            destinationLocation: Value(route?.destination.location),
            destinationLatitude: Value(route?.destination.latitude),
            destinationLongitude: Value(route?.destination.longitude),
          ),
        );
    return _toFlight(row);
  }

  Future<void> updateTracking(int flightId, FlightTracking tracking) async {
    final position = tracking.latestPosition;
    await (_database.update(
      _database.flights,
    )..where((row) => row.id.equals(flightId))).write(
      FlightsCompanion(
        hasBeenAirborne: Value(tracking.hasBeenAirborne),
        lastKnownOnGround: Value(tracking.lastKnownOnGround),
        firstAirborneAt: Value(
          tracking.firstAirborneAt?.millisecondsSinceEpoch,
        ),
        latestLatitude: Value(position?.latitude),
        latestLongitude: Value(position?.longitude),
        latestTimestamp: Value(position?.timestamp.millisecondsSinceEpoch),
        latestBarometricAltitudeFeet: Value(position?.barometricAltitudeFeet),
        latestOnGround: Value(position?.onGround),
        latestGeometricAltitudeFeet: Value(position?.geometricAltitudeFeet),
        latestTrackDegrees: Value(position?.trackDegrees),
        latestTrueHeadingDegrees: Value(position?.trueHeadingDegrees),
        latestGroundSpeedKnots: Value(position?.groundSpeedKnots),
        latestIndicatedAirspeedKnots: Value(position?.indicatedAirspeedKnots),
        latestMach: Value(position?.mach),
        latestVerticalRateFeetPerMinute: Value(
          position?.verticalRateFeetPerMinute,
        ),
      ),
    );
  }

  Future<void> updateIdentity(
    int flightId, {
    required String? hexAddress,
    required String? expectedCallsign,
  }) async {
    await (_database.update(
      _database.flights,
    )..where((row) => row.id.equals(flightId))).write(
      FlightsCompanion(
        hexAddress: Value(hexAddress),
        expectedCallsign: Value(expectedCallsign),
      ),
    );
  }

  /// Takes a notification of a flight for delivery and reports whether this
  /// call is the one that got it. The marker is written in the same statement
  /// that checks it, so a caller working from an older copy of the flight
  /// cannot put the same notification in front of the user a second time.
  Future<bool> claimNotification(
    int flightId,
    FlightNotification kind,
    DateTime deliveredAt,
  ) async {
    final at = Value(deliveredAt.millisecondsSinceEpoch);
    final update = _database.update(_database.flights)
      ..where((row) => row.id.equals(flightId) & _markerOf(row, kind).isNull());
    final rows = await update.write(switch (kind) {
      FlightNotification.departed => FlightsCompanion(departedNotifiedAt: at),
      // The pending moment goes with it: what has been delivered is no longer
      // waiting on the system.
      FlightNotification.arrivingSoon => FlightsCompanion(
        arrivingSoonNotifiedAt: at,
        arrivingSoonScheduledFor: const Value(null),
      ),
      FlightNotification.landed => FlightsCompanion(landedNotifiedAt: at),
    });
    return rows > 0;
  }

  /// Remembers when the system is due to deliver a flight's arrival reminder,
  /// so a later run still knows about a reminder it did not schedule itself.
  Future<void> setArrivingSoonSchedule(int flightId, DateTime? at) async {
    await (_database.update(
      _database.flights,
    )..where((row) => row.id.equals(flightId))).write(
      FlightsCompanion(
        arrivingSoonScheduledFor: Value(at?.millisecondsSinceEpoch),
      ),
    );
  }

  /// Writes off the reminders whose moment has passed: the system delivered
  /// them, whether or not the app was running at the time.
  Future<void> markDueRemindersDelivered(DateTime now) async {
    final due =
        await (_database.select(_database.flights)..where(
              (row) => row.arrivingSoonScheduledFor.isSmallerOrEqualValue(
                now.millisecondsSinceEpoch,
              ),
            ))
            .get();
    for (final row in due) {
      await claimNotification(
        row.id,
        FlightNotification.arrivingSoon,
        _toUtcInstant(row.arrivingSoonScheduledFor!),
      );
    }
  }

  Future<void> appendTrailPoint(
    int flightId,
    FixPosition position,
    SourceId sourceId,
  ) async {
    await _database
        .into(_database.trailPoints)
        .insert(
          TrailPointsCompanion.insert(
            flightId: flightId,
            timestamp: position.timestamp.millisecondsSinceEpoch,
            latitude: position.latitude,
            longitude: position.longitude,
            sourceId: sourceId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> clearTrail(int flightId) async {
    await (_database.delete(
      _database.trailPoints,
    )..where((row) => row.flightId.equals(flightId))).go();
  }

  Future<void> resetNotificationMarkers(int flightId) async {
    await (_database.update(
      _database.flights,
    )..where((row) => row.id.equals(flightId))).write(
      const FlightsCompanion(
        departedNotifiedAt: Value(null),
        arrivingSoonNotifiedAt: Value(null),
        landedNotifiedAt: Value(null),
        arrivingSoonScheduledFor: Value(null),
      ),
    );
  }

  Stream<List<TrailPoint>> watchTrail(int flightId) {
    final query = _database.select(_database.trailPoints)
      ..where((row) => row.flightId.equals(flightId))
      ..orderBy([(row) => OrderingTerm(expression: row.timestamp)]);
    return query.watch().map((rows) => rows.map(_toTrailPoint).toList());
  }

  Future<void> deleteExpiredFlights(DateTime now) async {
    final rows = await _database.select(_database.flights).get();
    final expiredIds = rows
        .map(_toFlight)
        .where((flight) => hasFlightExpired(flight, now))
        .map((flight) => flight.id)
        .toList();
    if (expiredIds.isEmpty) {
      return;
    }
    await (_database.delete(
      _database.flights,
    )..where((row) => row.id.isIn(expiredIds))).go();
  }

  Future<void> deleteFlight(int flightId) async {
    await (_database.delete(
      _database.flights,
    )..where((row) => row.id.equals(flightId))).go();
  }
}

GeneratedColumn<int> _markerOf($FlightsTable row, FlightNotification kind) =>
    switch (kind) {
      FlightNotification.departed => row.departedNotifiedAt,
      FlightNotification.arrivingSoon => row.arrivingSoonNotifiedAt,
      FlightNotification.landed => row.landedNotifiedAt,
    };

Flight _toFlight(FlightRow row) => Flight(
  id: row.id,
  lookupKind: row.lookupKind,
  lookupValue: row.lookupValue,
  departureDate: _toCalendarDate(row.departureDate),
  departureTime: _toDayTime(row.departureMinutesSinceMidnight),
  departureTimeInterpretation: row.departureTimeInterpretation,
  note: row.note,
  hexAddress: row.hexAddress,
  expectedCallsign: row.expectedCallsign,
  route: _toRoute(row),
  tracking: FlightTracking(
    latestPosition: _toPosition(row),
    hasBeenAirborne: row.hasBeenAirborne,
    lastKnownOnGround: row.lastKnownOnGround,
    firstAirborneAt: _toInstant(row.firstAirborneAt),
  ),
  notifications: NotificationMarkers(
    departedAt: _toInstant(row.departedNotifiedAt),
    arrivingSoonAt: _toInstant(row.arrivingSoonNotifiedAt),
    landedAt: _toInstant(row.landedNotifiedAt),
    arrivingSoonScheduledFor: _toInstant(row.arrivingSoonScheduledFor),
  ),
);

FlightRoute? _toRoute(FlightRow row) {
  final origin = _toAirport(
    row.originIcaoCode,
    row.originIataCode,
    row.originName,
    row.originLocation,
    row.originLatitude,
    row.originLongitude,
  );
  final destination = _toAirport(
    row.destinationIcaoCode,
    row.destinationIataCode,
    row.destinationName,
    row.destinationLocation,
    row.destinationLatitude,
    row.destinationLongitude,
  );
  if (origin == null || destination == null) {
    return null;
  }
  return FlightRoute(origin: origin, destination: destination);
}

RouteAirport? _toAirport(
  String? icaoCode,
  String? iataCode,
  String? name,
  String? location,
  double? latitude,
  double? longitude,
) {
  if (icaoCode == null ||
      name == null ||
      latitude == null ||
      longitude == null) {
    return null;
  }
  return RouteAirport(
    icaoCode: icaoCode,
    iataCode: iataCode,
    name: name,
    location: location,
    latitude: latitude,
    longitude: longitude,
  );
}

FixPosition? _toPosition(FlightRow row) {
  final latitude = row.latestLatitude;
  final longitude = row.latestLongitude;
  final timestamp = row.latestTimestamp;
  if (latitude == null || longitude == null || timestamp == null) {
    return null;
  }
  return FixPosition(
    latitude: latitude,
    longitude: longitude,
    timestamp: _toUtcInstant(timestamp),
    barometricAltitudeFeet: row.latestBarometricAltitudeFeet,
    onGround: row.latestOnGround,
    geometricAltitudeFeet: row.latestGeometricAltitudeFeet,
    trackDegrees: row.latestTrackDegrees,
    trueHeadingDegrees: row.latestTrueHeadingDegrees,
    groundSpeedKnots: row.latestGroundSpeedKnots,
    indicatedAirspeedKnots: row.latestIndicatedAirspeedKnots,
    mach: row.latestMach,
    verticalRateFeetPerMinute: row.latestVerticalRateFeetPerMinute,
  );
}

TrailPoint _toTrailPoint(TrailPointRow row) => TrailPoint(
  timestamp: _toUtcInstant(row.timestamp),
  latitude: row.latitude,
  longitude: row.longitude,
  sourceId: row.sourceId,
);

DateTime? _toInstant(int? epochMilliseconds) =>
    epochMilliseconds == null ? null : _toUtcInstant(epochMilliseconds);

DateTime _toUtcInstant(int epochMilliseconds) =>
    DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true);

String _toIsoDate(CalendarDate date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DayTime? _toDayTime(int? minutesSinceMidnight) => minutesSinceMidnight == null
    ? null
    : DayTime.fromMinutesSinceMidnight(minutesSinceMidnight);

CalendarDate _toCalendarDate(String isoDate) => CalendarDate(
  int.parse(isoDate.substring(0, 4)),
  int.parse(isoDate.substring(5, 7)),
  int.parse(isoDate.substring(8, 10)),
);
