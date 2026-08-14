import 'package:drift/drift.dart';

import '../domain/calendar_date.dart';
import '../domain/fix.dart';
import '../domain/flight.dart';
import '../domain/flight_state.dart';
import '../domain/source_id.dart';
import '../domain/trail_point.dart';
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
    String? note,
    String? hexAddress,
    String? expectedCallsign,
  }) async {
    final row = await _database
        .into(_database.flights)
        .insertReturning(
          FlightsCompanion.insert(
            lookupKind: lookupKind,
            lookupValue: lookupValue,
            departureDate: _toIsoDate(departureDate),
            note: Value(note),
            hexAddress: Value(hexAddress),
            expectedCallsign: Value(expectedCallsign),
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

Flight _toFlight(FlightRow row) => Flight(
  id: row.id,
  lookupKind: row.lookupKind,
  lookupValue: row.lookupValue,
  departureDate: _toCalendarDate(row.departureDate),
  note: row.note,
  hexAddress: row.hexAddress,
  expectedCallsign: row.expectedCallsign,
  tracking: FlightTracking(
    latestPosition: _toPosition(row),
    hasBeenAirborne: row.hasBeenAirborne,
    lastKnownOnGround: row.lastKnownOnGround,
  ),
);

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

DateTime _toUtcInstant(int epochMilliseconds) =>
    DateTime.fromMillisecondsSinceEpoch(epochMilliseconds, isUtc: true);

String _toIsoDate(CalendarDate date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

CalendarDate _toCalendarDate(String isoDate) => CalendarDate(
  int.parse(isoDate.substring(0, 4)),
  int.parse(isoDate.substring(5, 7)),
  int.parse(isoDate.substring(8, 10)),
);
