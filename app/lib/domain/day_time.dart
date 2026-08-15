const _minutesPerHour = 60;

class DayTime {
  const DayTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hour is outside a day'),
      assert(minute >= 0 && minute < _minutesPerHour, 'minute is outside hour');

  DayTime.fromMinutesSinceMidnight(int minutesSinceMidnight)
    : this(
        minutesSinceMidnight ~/ _minutesPerHour,
        minutesSinceMidnight % _minutesPerHour,
      );

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * _minutesPerHour + minute;

  @override
  bool operator ==(Object other) =>
      other is DayTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}
