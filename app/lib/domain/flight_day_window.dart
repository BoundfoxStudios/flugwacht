import 'calendar_date.dart';

class FlightDayWindow {
  FlightDayWindow.forDepartureDate(CalendarDate departureDate)
    : start = DateTime(
        departureDate.year,
        departureDate.month,
        departureDate.day,
      ),
      end = DateTime(
        departureDate.year,
        departureDate.month,
        departureDate.day + 2,
      );

  final DateTime start;
  final DateTime end;

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);
}
