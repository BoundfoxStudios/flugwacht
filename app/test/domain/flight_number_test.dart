import 'package:flugwacht/domain/flight_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the same flight number regardless of case and spacing', () {
    const expected = FlightNumber('LH', '400');
    expect(FlightNumber.tryParse('LH 400'), expected);
    expect(FlightNumber.tryParse('lh400'), expected);
    expect(FlightNumber.tryParse('LH400'), expected);
    expect(FlightNumber.tryParse('  lh 4 00 '), expected);
  });

  test('strips leading zeros from the number', () {
    expect(FlightNumber.tryParse('LH 0400'), const FlightNumber('LH', '400'));
  });

  test('keeps a single zero for an all-zero number', () {
    expect(FlightNumber.tryParse('LH 0000'), const FlightNumber('LH', '0'));
  });

  test('parses a suffix letter after the number', () {
    expect(FlightNumber.tryParse('4U 22A'), const FlightNumber('4U', '22A'));
    expect(FlightNumber.tryParse('LH 1AB'), const FlightNumber('LH', '1AB'));
  });

  test('parses the three code shapes the standing data rules allow', () {
    expect(FlightNumber.tryParse('DLH400'), const FlightNumber('DLH', '400'));
    expect(FlightNumber.tryParse('U2 8511'), const FlightNumber('U2', '8511'));
    expect(FlightNumber.tryParse('8Z 123'), const FlightNumber('8Z', '123'));
  });

  test('joins code and number into the normalized flight number', () {
    expect(FlightNumber.tryParse('lh 0400')?.normalized, 'LH400');
  });

  test('rejects input without a code or without a number', () {
    expect(FlightNumber.tryParse(''), isNull);
    expect(FlightNumber.tryParse('LH'), isNull);
    expect(FlightNumber.tryParse('400'), isNull);
    expect(FlightNumber.tryParse('LHA'), isNull);
  });

  test('rejects a code the standing data rules do not allow', () {
    expect(FlightNumber.tryParse('L1H400'), isNull);
    expect(FlightNumber.tryParse('ABCD400'), isNull);
  });

  test('rejects a number longer than four characters', () {
    expect(FlightNumber.tryParse('LH 12345'), isNull);
    expect(FlightNumber.tryParse('LH 012345'), isNull);
    expect(FlightNumber.tryParse('LH 123AB'), isNull);
  });

  test('rejects more than two suffix letters', () {
    expect(FlightNumber.tryParse('LH 1ABC'), isNull);
  });

  test('rejects characters other than letters and digits', () {
    expect(FlightNumber.tryParse('LH-400'), isNull);
    expect(FlightNumber.tryParse('LH/400'), isNull);
  });
}
