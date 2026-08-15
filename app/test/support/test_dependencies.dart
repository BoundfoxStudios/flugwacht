import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flugwacht/data/airline_directory.dart';
import 'package:flugwacht/data/database.dart';
import 'package:flugwacht/data/flight_repository.dart';
import 'package:flugwacht/data/route_lookup.dart';
import 'package:flugwacht/ui/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

GoRouter createTestAppRouter() => createAppRouter(
  flightRepository: createTestRepository(),
  airlineDirectory: createTestAirlineDirectory(),
  routeLookup: FakeRouteLookup(),
);

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
