sealed class SignalAge {
  const SignalAge();
}

final class SignalAgeSeconds extends SignalAge {
  const SignalAgeSeconds(this.seconds);

  final int seconds;

  @override
  bool operator ==(Object other) =>
      other is SignalAgeSeconds && other.seconds == seconds;

  @override
  int get hashCode => seconds.hashCode;

  @override
  String toString() => 'SignalAgeSeconds($seconds)';
}

final class SignalAgeMinutes extends SignalAge {
  const SignalAgeMinutes(this.minutes);

  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is SignalAgeMinutes && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => 'SignalAgeMinutes($minutes)';
}

final class SignalAgeHours extends SignalAge {
  const SignalAgeHours(this.hours, this.minutes);

  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is SignalAgeHours &&
      other.hours == hours &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(hours, minutes);

  @override
  String toString() => 'SignalAgeHours($hours, $minutes)';
}

/// Breaks the time since the latest position down into the unit the sheet
/// shows it in; a position from the future counts as brand new.
SignalAge signalAgeOf(Duration age) {
  if (age.inSeconds < 60) {
    return SignalAgeSeconds(age.isNegative ? 0 : age.inSeconds);
  }
  if (age.inMinutes < 60) {
    return SignalAgeMinutes(age.inMinutes);
  }
  return SignalAgeHours(age.inHours, age.inMinutes.remainder(60));
}
