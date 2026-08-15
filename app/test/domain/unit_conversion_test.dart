import 'package:flugwacht/domain/unit_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts a cruising altitude to whole meters', () {
    expect(metersFromFeet(37000), 11278);
  });

  test('converts a cruising speed to whole kilometers per hour', () {
    expect(kilometersPerHourFromKnots(473), 876);
  });

  test('rounds to the nearest whole unit', () {
    expect(metersFromFeet(1.7), 1);
    expect(kilometersPerHourFromKnots(0.2), 0);
  });

  test('has no value without a measurement', () {
    expect(metersFromFeet(null), isNull);
    expect(kilometersPerHourFromKnots(null), isNull);
  });
}
