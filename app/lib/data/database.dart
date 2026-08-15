import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/flight.dart';
import '../domain/source_id.dart';

part 'database.g.dart';

@DataClassName('FlightRow')
class Flights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lookupKind => textEnum<FlightLookupKind>()();
  TextColumn get lookupValue => text()();
  TextColumn get departureDate => text()();
  TextColumn get note => text().nullable()();
  TextColumn get hexAddress => text().nullable()();
  TextColumn get expectedCallsign => text().nullable()();
  TextColumn get originIcaoCode => text().nullable()();
  TextColumn get originIataCode => text().nullable()();
  TextColumn get originName => text().nullable()();
  TextColumn get originLocation => text().nullable()();
  RealColumn get originLatitude => real().nullable()();
  RealColumn get originLongitude => real().nullable()();
  TextColumn get destinationIcaoCode => text().nullable()();
  TextColumn get destinationIataCode => text().nullable()();
  TextColumn get destinationName => text().nullable()();
  TextColumn get destinationLocation => text().nullable()();
  RealColumn get destinationLatitude => real().nullable()();
  RealColumn get destinationLongitude => real().nullable()();
  BoolColumn get hasBeenAirborne =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get lastKnownOnGround => boolean().nullable()();
  RealColumn get latestLatitude => real().nullable()();
  RealColumn get latestLongitude => real().nullable()();
  IntColumn get latestTimestamp => integer().nullable()();
  RealColumn get latestBarometricAltitudeFeet => real().nullable()();
  BoolColumn get latestOnGround => boolean().nullable()();
  RealColumn get latestGeometricAltitudeFeet => real().nullable()();
  RealColumn get latestTrackDegrees => real().nullable()();
  RealColumn get latestTrueHeadingDegrees => real().nullable()();
  RealColumn get latestGroundSpeedKnots => real().nullable()();
  RealColumn get latestIndicatedAirspeedKnots => real().nullable()();
  RealColumn get latestMach => real().nullable()();
  RealColumn get latestVerticalRateFeetPerMinute => real().nullable()();
}

@DataClassName('TrailPointRow')
class TrailPoints extends Table {
  IntColumn get flightId =>
      integer().references(Flights, #id, onDelete: KeyAction.cascade)();
  IntColumn get timestamp => integer()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get sourceId => textEnum<SourceId>()();

  @override
  Set<Column<Object>> get primaryKey => {flightId, timestamp};
}

@DriftDatabase(tables: [Flights, TrailPoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'flugwacht'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
