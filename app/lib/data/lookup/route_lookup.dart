import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/flight_number.dart';
import '../../domain/flight_route.dart';
import 'csv_parser.dart';

const _baseUrl =
    'https://raw.githubusercontent.com/vradarserver/standing-data/main';

sealed class RouteLookupResult {
  const RouteLookupResult();
}

class RouteFound extends RouteLookupResult {
  const RouteFound(this.callsign, this.route);

  final String callsign;
  final FlightRoute route;
}

class RouteNotFound extends RouteLookupResult {
  const RouteNotFound();
}

class RouteLookupFailure extends RouteLookupResult {
  const RouteLookupFailure();
}

class RouteLookup {
  RouteLookup({
    required this._client,
    this._timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final Duration _timeout;

  /// Resolves the route of the first candidate the standing data knows,
  /// keeping the airport files of one lookup in memory.
  Future<RouteLookupResult> lookup(List<String> callsignCandidates) async {
    final airportRowsByPath = <String, List<List<String>>>{};
    try {
      for (final callsign in callsignCandidates) {
        final route = await _route(callsign, airportRowsByPath);
        if (route != null) {
          return RouteFound(callsign, route);
        }
      }
      return const RouteNotFound();
    } on _UnavailableData {
      return const RouteLookupFailure();
    }
  }

  Future<FlightRoute?> _route(
    String callsign,
    Map<String, List<List<String>>> airportRowsByPath,
  ) async {
    final flightNumber = FlightNumber.tryParse(callsign);
    if (flightNumber == null) {
      return null;
    }
    final airportCodes = await _airportCodes(flightNumber, callsign);
    if (airportCodes == null) {
      return null;
    }
    final origin = await _airport(airportCodes.first, airportRowsByPath);
    final destination = await _airport(airportCodes.last, airportRowsByPath);
    if (origin == null || destination == null) {
      return null;
    }
    return FlightRoute(origin: origin, destination: destination);
  }

  /// The airports the callsign flies through, or null when the standing data
  /// carries no usable route for it.
  Future<List<String>?> _airportCodes(
    FlightNumber flightNumber,
    String callsign,
  ) async {
    final code = flightNumber.airlineCode;
    final directory = 'routes/schema-01/${code[0]}';
    var rows = await _rows('$directory/$code-all.csv');
    // Airlines above 10 000 routes are split into one file per leading digit
    // and then carry no all-routes file.
    rows ??= await _rows('$directory/$code-${flightNumber.number[0]}.csv');
    if (rows == null) {
      return null;
    }
    for (final row in rows.skip(1)) {
      if (row.first != callsign) {
        continue;
      }
      if (row.length < 5) {
        throw const _UnavailableData();
      }
      final airportCodes = row[4]
          .split('-')
          .where((code) => code.isNotEmpty)
          .toList();
      return airportCodes.length < 2 ? null : airportCodes;
    }
    return null;
  }

  Future<RouteAirport?> _airport(
    String icaoCode,
    Map<String, List<List<String>>> airportRowsByPath,
  ) async {
    if (icaoCode.length < 2) {
      return null;
    }
    final path =
        'airports/schema-01/${icaoCode[0]}/${icaoCode.substring(0, 2)}.csv';
    final rows = airportRowsByPath[path] ??=
        await _rows(path) ?? const <List<String>>[];
    for (final row in rows.skip(1)) {
      if (row.first != icaoCode) {
        continue;
      }
      if (row.length < 8) {
        throw const _UnavailableData();
      }
      final latitude = double.tryParse(row[6]);
      final longitude = double.tryParse(row[7]);
      if (latitude == null || longitude == null) {
        throw const _UnavailableData();
      }
      return RouteAirport(
        icaoCode: row.first,
        iataCode: row[3].isEmpty ? null : row[3],
        name: row[1],
        location: row[4].isEmpty ? null : row[4],
        latitude: latitude,
        longitude: longitude,
      );
    }
    return null;
  }

  /// The parsed file, or null when the standing data has no such file.
  Future<List<List<String>>?> _rows(String path) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/$path'))
          .timeout(_timeout);
    } on Object catch (_) {
      throw const _UnavailableData();
    }
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const _UnavailableData();
    }
    try {
      return parseCsvRows(utf8.decode(response.bodyBytes));
    } on Object catch (_) {
      throw const _UnavailableData();
    }
  }
}

class _UnavailableData implements Exception {
  const _UnavailableData();
}
