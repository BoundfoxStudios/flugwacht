import 'dart:io';

import 'package:flugwacht/data/airline_directory.dart';
import 'package:flugwacht/domain/flight_number.dart';
import 'package:flutter_test/flutter_test.dart';

const _csv =
    'Code,Name,ICAO,IATA,PositioningFlightPattern,CharterFlightPattern\n'
    'DLH,Lufthansa,DLH,LH,,\n'
    'GEC,Lufthansa Cargo,GEC,LH,,\n'
    'RYR,Ryanair,RYR,FR,^\\d\$,\n'
    '1B,Abacus International,,1B,,\n'
    'ACR,"Aerocenter, Escuela",ACR,,,\n';

const _lowCostCarrierIataCodes = [
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
];

void main() {
  final directory = AirlineDirectory.fromCsv(_csv);

  test('maps an ambiguous iata code to every airline carrying it', () {
    expect(directory.callsignCandidates(const FlightNumber('LH', '400')), [
      'DLH400',
      'GEC400',
    ]);
  });

  test('turns an icao code into exactly one candidate', () {
    expect(directory.callsignCandidates(const FlightNumber('DLH', '400')), [
      'DLH400',
    ]);
  });

  test('ignores rows that do not carry all airline columns', () {
    final truncated = AirlineDirectory.fromCsv(
      'Code,Name,ICAO,IATA\nDLH,Lufthansa\nGEC,Lufthansa Cargo,GEC,LH\n',
    );
    expect(truncated.callsignCandidates(const FlightNumber('LH', '400')), [
      'GEC400',
    ]);
  });

  test('yields no candidates for an unknown code', () {
    expect(
      directory.callsignCandidates(const FlightNumber('ZZ', '400')),
      isEmpty,
    );
  });

  test('yields no candidates for an airline without an icao code', () {
    expect(
      directory.callsignCandidates(const FlightNumber('1B', '123')),
      isEmpty,
    );
  });

  test('resolves airline names by icao and by iata code', () {
    expect(directory.airlineName('DLH'), 'Lufthansa');
    expect(directory.airlineName('GEC'), 'Lufthansa Cargo');
    expect(directory.airlineName('LH'), 'Lufthansa');
    expect(directory.airlineName('1B'), 'Abacus International');
    expect(directory.airlineName('ZZ'), isNull);
  });

  test('detects low cost carriers by iata code', () {
    expect(AirlineDirectory.isLowCostCarrier('FR'), isTrue);
    expect(AirlineDirectory.isLowCostCarrier('U2'), isTrue);
    expect(AirlineDirectory.isLowCostCarrier('W6'), isTrue);
    expect(AirlineDirectory.isLowCostCarrier('LH'), isFalse);
    expect(AirlineDirectory.isLowCostCarrier('DLH'), isFalse);
  });

  group('bundled airlines.csv', () {
    final bundled = AirlineDirectory.fromCsv(
      File(AirlineDirectory.assetPath).readAsStringSync(),
    );

    test('resolves Lufthansa and Lufthansa Cargo for LH', () {
      expect(bundled.callsignCandidates(const FlightNumber('LH', '400')), [
        'DLH400',
        'GEC400',
      ]);
      expect(bundled.airlineName('DLH'), 'Lufthansa');
    });

    test('carries an airline for every low cost carrier code', () {
      for (final code in _lowCostCarrierIataCodes) {
        expect(
          bundled.callsignCandidates(FlightNumber(code, '1')),
          isNotEmpty,
          reason: 'no airline carries the iata code $code',
        );
      }
    });
  });
}
