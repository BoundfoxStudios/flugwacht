import 'package:flugwacht/domain/remaining_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts whole minutes below an hour', () {
    expect(
      remainingTimeOf(const Duration(minutes: 59, seconds: 30)),
      const RemainingTimeMinutes(59),
    );
  });

  test('drops the seconds of a flight about to arrive', () {
    expect(
      remainingTimeOf(const Duration(seconds: 30)),
      const RemainingTimeMinutes(0),
    );
  });

  test('turns into hours at the hour boundary', () {
    expect(
      remainingTimeOf(const Duration(minutes: 60)),
      const RemainingTimeHours(1, 0),
    );
  });

  test('splits hours and minutes above the boundary', () {
    expect(
      remainingTimeOf(const Duration(hours: 2, minutes: 10, seconds: 45)),
      const RemainingTimeHours(2, 10),
    );
  });

  test('clamps an arrival that has passed to zero', () {
    expect(
      remainingTimeOf(const Duration(hours: -3)),
      const RemainingTimeMinutes(0),
    );
  });
}
