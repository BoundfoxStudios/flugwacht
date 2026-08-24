import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/flight_number.dart';
import '../../domain/flight_route.dart';
import 'csv_parser.dart';

const _baseUrl =
    'https://raw.githubusercontent.com/vradarserver/standing-data/main';

/// A marketed number carries the full width a flight number can have, and what
/// its leading digit leaves behind still has to be a number of its own: a
/// single digit would match unrelated flights over the same route.
const _marketedNumberDigits = 4;
const _leastOperatedDigits = 2;

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
        final found = await _route(callsign, airportRowsByPath);
        if (found != null) {
          return found;
        }
      }
      return const RouteNotFound();
    } on _UnavailableData {
      return const RouteLookupFailure();
    }
  }

  Future<RouteFound?> _route(
    String callsign,
    Map<String, List<List<String>>> airportRowsByPath,
  ) async {
    final flightNumber = FlightNumber.tryParse(callsign);
    if (flightNumber == null) {
      return null;
    }
    final rows = await _routeRows(flightNumber);
    if (rows == null) {
      return null;
    }
    final row = _rowFor(rows, callsign);
    if (row == null) {
      return null;
    }
    final airportCodes = _airportCodesOf(row);
    if (airportCodes == null) {
      return null;
    }
    final origin = await _airport(airportCodes.first, airportRowsByPath);
    final destination = await _airport(airportCodes.last, airportRowsByPath);
    if (origin == null || destination == null) {
      return null;
    }
    return RouteFound(
      _operatedCallsign(rows, flightNumber, row[4]) ?? callsign,
      FlightRoute(origin: origin, destination: destination),
    );
  }

  /// Every route of the callsign's airline, or null when the standing data
  /// carries no file for it.
  Future<List<List<String>>?> _routeRows(FlightNumber flightNumber) async {
    final code = flightNumber.airlineCode;
    final directory = 'routes/schema-01/${code[0]}';
    // Airlines above 10 000 routes are split into one file per leading digit
    // and then carry no all-routes file.
    return await _rows('$directory/$code-all.csv') ??
        await _rows('$directory/$code-${flightNumber.number[0]}.csv');
  }

  List<String>? _rowFor(List<List<String>> rows, String callsign) {
    for (final row in rows.skip(1)) {
      if (row.first != callsign) {
        continue;
      }
      if (row.length < 5) {
        throw const _UnavailableData();
      }
      return row;
    }
    return null;
  }

  /// The airports the row flies through, or null when it carries no usable
  /// route: the column is the aircraft's whole rotation rather than one leg,
  /// so a chain ending where it started (CFG1402 reads EDDF-GCLP-GCFV-EDDF)
  /// names its own origin as the destination.
  List<String>? _airportCodesOf(List<String> row) {
    final airportCodes = row[4]
        .split('-')
        .where((code) => code.isNotEmpty)
        .toList();
    return airportCodes.length < 2 || airportCodes.first == airportCodes.last
        ? null
        : airportCodes;
  }

  /// The callsign the flight goes by where the airline markets it under a
  /// number of its own: it puts a marketing digit in front of the number it
  /// files, so Condor sells DE2016 and flies as CFG016. Only the standing data
  /// tells the two apart, by carrying the shorter number over the same route.
  String? _operatedCallsign(
    List<List<String>> rows,
    FlightNumber marketed,
    String airportCodes,
  ) {
    if (marketed.digits.length != _marketedNumberDigits) {
      return null;
    }
    final operated = FlightNumber.tryParse(
      '${marketed.airlineCode}${marketed.digits.substring(1)}'
      '${marketed.suffix}',
    );
    if (operated == null || operated.digits.length < _leastOperatedDigits) {
      return null;
    }
    final row = _rowFor(rows, operated.normalized);
    return row != null && row[4] == airportCodes ? operated.normalized : null;
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
