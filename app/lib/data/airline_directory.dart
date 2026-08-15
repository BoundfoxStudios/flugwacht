import 'package:flutter/services.dart';

import '../domain/flight_number.dart';
import 'csv_parser.dart';

// Ryanair, easyJet and Wizz Air including their sister air operator
// certificates; 8Z is shared with Congo Airways, whose flights then show the
// hint as well.
const _lowCostCarrierIataCodes = {
  'FR',
  'RK',
  'U2',
  'EC',
  'DS',
  'W6',
  'W4',
  'W9',
  'WU',
  '8Z',
};

class AirlineDirectory {
  AirlineDirectory._(this._airlinesByIcaoCode, this._airlinesByIataCode);

  factory AirlineDirectory.fromCsv(String csv) {
    final airlinesByIcaoCode = <String, _Airline>{};
    final airlinesByIataCode = <String, List<_Airline>>{};
    for (final row in parseCsvRows(csv).skip(1)) {
      if (row.length < 4) {
        continue;
      }
      final airline = _Airline(
        name: row[1],
        icaoCode: row[2],
        iataCode: row[3],
      );
      if (airline.icaoCode.isNotEmpty) {
        airlinesByIcaoCode.putIfAbsent(airline.icaoCode, () => airline);
      }
      if (airline.iataCode.isNotEmpty) {
        airlinesByIataCode
            .putIfAbsent(airline.iataCode, () => <_Airline>[])
            .add(airline);
      }
    }
    return AirlineDirectory._(airlinesByIcaoCode, airlinesByIataCode);
  }

  static const assetPath = 'assets/data/airlines.csv';

  static Future<AirlineDirectory> loadFromAssets([AssetBundle? bundle]) async =>
      AirlineDirectory.fromCsv(
        await (bundle ?? rootBundle).loadString(assetPath),
      );

  final Map<String, _Airline> _airlinesByIcaoCode;
  final Map<String, List<_Airline>> _airlinesByIataCode;

  /// The callsigns the flight number can stand for, in the order of the
  /// airline file: an icao code resolves to itself, an iata code to every
  /// airline carrying it.
  List<String> callsignCandidates(FlightNumber flightNumber) {
    final code = flightNumber.airlineCode;
    if (_airlinesByIcaoCode.containsKey(code)) {
      return ['$code${flightNumber.number}'];
    }
    return [
      for (final airline in _airlinesByIataCode[code] ?? const <_Airline>[])
        if (airline.icaoCode.isNotEmpty)
          '${airline.icaoCode}${flightNumber.number}',
    ];
  }

  String? airlineName(String code) =>
      (_airlinesByIcaoCode[code] ?? _airlinesByIataCode[code]?.first)?.name;

  bool isLowCostCarrier(String code) => _lowCostCarrierIataCodes.contains(code);
}

class _Airline {
  const _Airline({
    required this.name,
    required this.icaoCode,
    required this.iataCode,
  });

  final String name;
  final String icaoCode;
  final String iataCode;
}
