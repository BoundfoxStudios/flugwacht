import 'calendar_date.dart';

enum RelativeDay { today, yesterday, earlier }

/// How near a departure day is to the current one, so a row can name it in
/// words instead of a date.
RelativeDay relativeDayOf(CalendarDate date, DateTime now) {
  if (date == CalendarDate(now.year, now.month, now.day)) {
    return RelativeDay.today;
  }
  // Counts the day down instead of subtracting 24 hours, so a daylight saving
  // switch cannot land the result on the wrong day.
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  return date == CalendarDate(yesterday.year, yesterday.month, yesterday.day)
      ? RelativeDay.yesterday
      : RelativeDay.earlier;
}
