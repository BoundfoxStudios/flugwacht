import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalendarDate dateOf(int year, int month, int day) =>
      CalendarDate(year, month, day);

  test('is equal to a date with the same calendar components', () {
    expect(dateOf(2026, 3, 17), dateOf(2026, 3, 17));
    expect(dateOf(2026, 3, 17).hashCode, dateOf(2026, 3, 17).hashCode);
  });

  test('differs when any calendar component differs', () {
    expect(dateOf(2026, 3, 17), isNot(dateOf(2026, 3, 18)));
    expect(dateOf(2026, 3, 17), isNot(dateOf(2026, 4, 17)));
    expect(dateOf(2026, 3, 17), isNot(dateOf(2027, 3, 17)));
  });
}
