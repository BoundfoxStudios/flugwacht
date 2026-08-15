sealed class RemainingTime {
  const RemainingTime();
}

final class RemainingTimeMinutes extends RemainingTime {
  const RemainingTimeMinutes(this.minutes);

  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is RemainingTimeMinutes && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => 'RemainingTimeMinutes($minutes)';
}

final class RemainingTimeHours extends RemainingTime {
  const RemainingTimeHours(this.hours, this.minutes);

  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is RemainingTimeHours &&
      other.hours == hours &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(hours, minutes);

  @override
  String toString() => 'RemainingTimeHours($hours, $minutes)';
}

/// Breaks the time left until the arrival down into the unit the estimate is
/// shown in; an arrival that has passed counts as none left.
RemainingTime remainingTimeOf(Duration remaining) {
  if (remaining.inMinutes < 60) {
    return RemainingTimeMinutes(remaining.isNegative ? 0 : remaining.inMinutes);
  }
  return RemainingTimeHours(
    remaining.inHours,
    remaining.inMinutes.remainder(60),
  );
}
