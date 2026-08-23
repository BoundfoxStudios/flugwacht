import 'package:flugwacht/data/notifications/notification_ids.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Two flights whose slots overlapped would cancel and replace each other's
  /// notifications, which nothing above this ever checks for.
  test('gives every flight and kind an id of its own', () {
    final ids = <int>{};
    for (var flightId = 0; flightId < 50; flightId++) {
      for (final kind in FlightNotification.values) {
        ids.add(notificationIdOf(kind, flightId));
      }
      ids
        ..add(liveActivityReminderIdOf(flightId))
        ..add(flightCardIdOf(flightId));
    }

    expect(ids, hasLength(50 * (FlightNotification.values.length + 2)));
  });

  test('keeps the same slot for a flight across calls', () {
    expect(flightCardIdOf(7), flightCardIdOf(7));
    expect(
      notificationIdOf(FlightNotification.arrivingSoon, 7),
      notificationIdOf(FlightNotification.arrivingSoon, 7),
    );
  });
}
