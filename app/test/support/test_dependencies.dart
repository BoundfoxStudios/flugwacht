import 'dart:async';
import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flugwacht/data/airline_directory.dart';
import 'package:flugwacht/data/database.dart';
import 'package:flugwacht/data/flight_repository.dart';
import 'package:flugwacht/data/lookup_result.dart';
import 'package:flugwacht/data/route_lookup.dart';
import 'package:flugwacht/data/source_adapter.dart';
import 'package:flugwacht/data/source_setting.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/ui/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const testAirlinesCsv =
    'Code,Name,ICAO,IATA,PositioningFlightPattern,CharterFlightPattern\n'
    'DLH,Lufthansa,DLH,LH,,\n'
    'GEC,Lufthansa Cargo,GEC,LH,,\n'
    'RYR,Ryanair,RYR,FR,,\n';

FlightRepository createTestRepository() {
  final database = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(database.close);
  return FlightRepository(database);
}

AirlineDirectory createTestAirlineDirectory() =>
    AirlineDirectory.fromCsv(testAirlinesCsv);

/// A setting on an empty in-memory store, so no test sees what another stored.
Future<SourceSetting> createTestSourceSetting() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final setting = await SourceSetting.load();
  addTearDown(setting.dispose);
  return setting;
}

Future<GoRouter> createTestAppRouter() async => createAppRouter(
  flightRepository: createTestRepository(),
  airlineDirectory: createTestAirlineDirectory(),
  routeLookup: FakeRouteLookup(),
  sourceSetting: await createTestSourceSetting(),
  tileProvider: StubTileProvider(),
);

class FakeFlightRepository implements FlightRepository {
  final _flights = StreamController<List<Flight>>.broadcast();
  final _trails = StreamController<List<TrailPoint>>.broadcast();
  final expiryChecks = <DateTime>[];
  final watchedTrails = <int>[];
  final trackingUpdates = <(int, FlightTracking)>[];
  final trailAppends = <(int, FixPosition, SourceId)>[];
  final identityUpdates = <(int, String?, String?)>[];

  void emit(List<Flight> flights) => _flights.add(flights);

  void emitTrail(List<TrailPoint> trail) => _trails.add(trail);

  void dispose() {
    unawaited(_flights.close());
    unawaited(_trails.close());
  }

  @override
  Stream<List<Flight>> watchFlights() => _flights.stream;

  @override
  Stream<List<TrailPoint>> watchTrail(int flightId) {
    watchedTrails.add(flightId);
    return _trails.stream;
  }

  @override
  Future<void> deleteExpiredFlights(DateTime now) async =>
      expiryChecks.add(now);

  @override
  Future<void> updateTracking(int flightId, FlightTracking tracking) async =>
      trackingUpdates.add((flightId, tracking));

  @override
  Future<void> appendTrailPoint(
    int flightId,
    FixPosition position,
    SourceId sourceId,
  ) async => trailAppends.add((flightId, position, sourceId));

  @override
  Future<void> updateIdentity(
    int flightId, {
    required String? hexAddress,
    required String? expectedCallsign,
  }) async => identityUpdates.add((flightId, hexAddress, expectedCallsign));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Serves a transparent pixel so no widget test ever requests a map tile.
class StubTileProvider extends TileProvider {
  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) => MemoryImage(_transparentPixel);
}

final _transparentPixel = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
  0x89, 0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
  0x42, 0x60, 0x82,
]);

/// Answers lookups from a script keyed by the queried value and records every
/// request in the order it arrived.
class FakeSourceAdapter implements SourceAdapter {
  final results = <String, LookupResult>{};
  final callsignRequests = <String>[];
  final hexAddressRequests = <String>[];
  final registrationRequests = <String>[];
  Completer<LookupResult>? pendingResult;

  @override
  Future<LookupResult> lookupByCallsign(String callsign) {
    callsignRequests.add(callsign);
    return _resultFor(callsign);
  }

  @override
  Future<LookupResult> lookupByHexAddress(String hexAddress) {
    hexAddressRequests.add(hexAddress);
    return _resultFor(hexAddress);
  }

  @override
  Future<LookupResult> lookupByRegistration(String registration) {
    registrationRequests.add(registration);
    return _resultFor(registration);
  }

  Future<LookupResult> _resultFor(String value) =>
      pendingResult?.future ??
      Future.value(results[value] ?? const LookupSuccess([]));
}

class FakeRouteLookup implements RouteLookup {
  FakeRouteLookup([this.result = const RouteNotFound()]);

  RouteLookupResult result;
  Completer<RouteLookupResult>? pendingResult;
  final requests = <List<String>>[];

  @override
  Future<RouteLookupResult> lookup(List<String> callsignCandidates) {
    requests.add(callsignCandidates);
    return pendingResult?.future ?? Future.value(result);
  }
}
