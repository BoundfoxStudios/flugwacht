import 'package:flugwacht/domain/signal_age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts a fresh signal in seconds', () {
    expect(signalAgeOf(const Duration(seconds: 3)), const SignalAgeSeconds(3));
    expect(signalAgeOf(Duration.zero), const SignalAgeSeconds(0));
    expect(
      signalAgeOf(const Duration(seconds: 59)),
      const SignalAgeSeconds(59),
    );
  });

  test('counts a signal in minutes from a full minute on', () {
    expect(signalAgeOf(const Duration(seconds: 60)), const SignalAgeMinutes(1));
    expect(
      signalAgeOf(const Duration(minutes: 42, seconds: 30)),
      const SignalAgeMinutes(42),
    );
    expect(
      signalAgeOf(const Duration(minutes: 59)),
      const SignalAgeMinutes(59),
    );
  });

  test('counts a signal in hours and minutes from a full hour on', () {
    expect(
      signalAgeOf(const Duration(minutes: 60)),
      const SignalAgeHours(1, 0),
    );
    expect(
      signalAgeOf(const Duration(hours: 2, minutes: 5, seconds: 59)),
      const SignalAgeHours(2, 5),
    );
    expect(
      signalAgeOf(const Duration(hours: 47, minutes: 59)),
      const SignalAgeHours(47, 59),
    );
  });

  test('counts a signal from the future as fresh', () {
    expect(signalAgeOf(const Duration(minutes: -2)), const SignalAgeSeconds(0));
  });
}
