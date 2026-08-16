import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/relative_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calls the current day today', () {
    expect(
      relativeDayOf(const CalendarDate(2026, 8, 16), DateTime(2026, 8, 16, 23)),
      RelativeDay.today,
    );
  });

  test('calls the day before the current one yesterday', () {
    expect(
      relativeDayOf(const CalendarDate(2026, 8, 15), DateTime(2026, 8, 16, 1)),
      RelativeDay.yesterday,
    );
  });

  test('counts back over a month boundary', () {
    expect(
      relativeDayOf(const CalendarDate(2026, 7, 31), DateTime(2026, 8, 1, 6)),
      RelativeDay.yesterday,
    );
  });

  test('counts back over a year boundary', () {
    expect(
      relativeDayOf(const CalendarDate(2025, 12, 31), DateTime(2026, 1, 1)),
      RelativeDay.yesterday,
    );
  });

  test('leaves anything older than yesterday to its date', () {
    expect(
      relativeDayOf(const CalendarDate(2026, 8, 14), DateTime(2026, 8, 16)),
      RelativeDay.earlier,
    );
  });

  test('keeps the same day of another month apart from today', () {
    expect(
      relativeDayOf(const CalendarDate(2026, 7, 16), DateTime(2026, 8, 16)),
      RelativeDay.earlier,
    );
  });
}
