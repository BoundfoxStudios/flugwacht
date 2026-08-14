import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/flight_day_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spans local midnight on the departure day until midnight two days '
      'later', () {
    final window = FlightDayWindow.forDepartureDate(
      const CalendarDate(2026, 3, 17),
    );
    expect(window.start, DateTime(2026, 3, 17));
    expect(window.end, DateTime(2026, 3, 19));
  });

  test('contains the start instant but not the end instant', () {
    final window = FlightDayWindow.forDepartureDate(
      const CalendarDate(2026, 3, 17),
    );
    expect(window.contains(window.start), isTrue);
    expect(window.contains(window.end), isFalse);
    expect(
      window.contains(window.start.subtract(const Duration(microseconds: 1))),
      isFalse,
    );
    expect(
      window.contains(window.end.subtract(const Duration(microseconds: 1))),
      isTrue,
    );
  });

  test('contains instants given in another time zone', () {
    final window = FlightDayWindow.forDepartureDate(
      const CalendarDate(2026, 3, 17),
    );
    expect(window.contains(window.start.toUtc()), isTrue);
    expect(window.contains(window.end.toUtc()), isFalse);
  });

  test('rolls over into the following month', () {
    final window = FlightDayWindow.forDepartureDate(
      const CalendarDate(2026, 1, 31),
    );
    expect(window.end, DateTime(2026, 2, 2));
  });

  test('rolls over into the following year', () {
    final window = FlightDayWindow.forDepartureDate(
      const CalendarDate(2026, 12, 31),
    );
    expect(window.end, DateTime(2027, 1, 2));
  });

  test('derives an identical window from an equal departure date', () {
    CalendarDate dateOf(int year, int month, int day) =>
        CalendarDate(year, month, day);

    final window = FlightDayWindow.forDepartureDate(dateOf(2026, 5, 4));
    final other = FlightDayWindow.forDepartureDate(dateOf(2026, 5, 4));
    expect(other.start, window.start);
    expect(other.end, window.end);
  });
}
