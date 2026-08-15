import 'package:flugwacht/domain/day_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DayTime timeOf(int hour, int minute) => DayTime(hour, minute);

  test('is equal to a time with the same clock components', () {
    expect(timeOf(16, 10), timeOf(16, 10));
    expect(timeOf(16, 10).hashCode, timeOf(16, 10).hashCode);
  });

  test('differs when any clock component differs', () {
    expect(timeOf(16, 10), isNot(timeOf(16, 11)));
    expect(timeOf(16, 10), isNot(timeOf(17, 10)));
  });

  test('rejects clock components outside a day', () {
    expect(() => timeOf(24, 0), throwsA(isA<AssertionError>()));
    expect(() => timeOf(-1, 0), throwsA(isA<AssertionError>()));
    expect(() => timeOf(16, 60), throwsA(isA<AssertionError>()));
    expect(() => timeOf(16, -1), throwsA(isA<AssertionError>()));
  });

  test('round-trips through the minutes since midnight', () {
    expect(timeOf(16, 10).minutesSinceMidnight, 970);
    expect(timeOf(0, 0).minutesSinceMidnight, 0);
    expect(timeOf(23, 59).minutesSinceMidnight, 1439);
    expect(DayTime.fromMinutesSinceMidnight(970), timeOf(16, 10));
    expect(DayTime.fromMinutesSinceMidnight(0), timeOf(0, 0));
    expect(DayTime.fromMinutesSinceMidnight(1439), timeOf(23, 59));
  });
}
