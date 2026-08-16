import 'arrival_estimate.dart';
import 'flight.dart';
import 'flight_notification.dart';
import 'flight_state.dart';

/// How far ahead of the estimated arrival the app calls it "arriving soon".
const arrivingSoonLeadTime = Duration(minutes: 30);

/// How far a pending reminder may sit off the estimate before it is worth
/// moving; the copy stays vague anyway, and every move resets an alarm.
const _rescheduleThreshold = Duration(minutes: 1);

/// What the pre-scheduled arrival reminder should do, so it also reaches the
/// user while the app is closed.
sealed class ArrivingSoonSchedule {
  const ArrivingSoonSchedule();
}

class KeepArrivingSoonSchedule extends ArrivingSoonSchedule {
  const KeepArrivingSoonSchedule();
}

class SetArrivingSoonSchedule extends ArrivingSoonSchedule {
  const SetArrivingSoonSchedule(this.at);

  final DateTime at;
}

class CancelArrivingSoonSchedule extends ArrivingSoonSchedule {
  const CancelArrivingSoonSchedule();
}

class NotificationPlan {
  const NotificationPlan({required this.events, required this.schedule});

  /// What the flight earned with the fix that just came in.
  final List<FlightNotification> events;

  final ArrivingSoonSchedule schedule;
}

/// What a flight's new facts mean for its notifications, derived from the
/// flight alone so nothing about it depends on the platform.
NotificationPlan planNotifications({
  required Flight flight,
  required FlightTracking previousTracking,
  required DateTime? pendingArrivingSoonAt,
  required bool Function(FlightNotification) isEnabled,
  required DateTime now,
}) {
  final tracking = flight.tracking;
  final markers = flight.notifications;
  bool isDue(FlightNotification kind) =>
      isEnabled(kind) && !markers.isDelivered(kind);

  final hasLanded = _isOnGroundAfterFlying(tracking);
  final events = [
    if (!previousTracking.hasBeenAirborne &&
        tracking.hasBeenAirborne &&
        isDue(FlightNotification.departed))
      FlightNotification.departed,
    if (!_isOnGroundAfterFlying(previousTracking) &&
        hasLanded &&
        isDue(FlightNotification.landed))
      FlightNotification.landed,
  ];

  final estimate = _freshEstimateOf(flight, now);
  final remaining = estimate?.arrivesAt.difference(now);
  if (!hasLanded &&
      remaining != null &&
      remaining <= arrivingSoonLeadTime &&
      isDue(FlightNotification.arrivingSoon)) {
    events.add(FlightNotification.arrivingSoon);
  }

  return NotificationPlan(
    events: events,
    schedule: _planSchedule(
      wantsReminder:
          !hasLanded &&
          isDue(FlightNotification.arrivingSoon) &&
          !events.contains(FlightNotification.arrivingSoon),
      remindAt: remaining != null && remaining > arrivingSoonLeadTime
          ? estimate!.arrivesAt.subtract(arrivingSoonLeadTime)
          : null,
      pendingAt: pendingArrivingSoonAt,
    ),
  );
}

ArrivingSoonSchedule _planSchedule({
  required bool wantsReminder,
  required DateTime? remindAt,
  required DateTime? pendingAt,
}) {
  if (!wantsReminder) {
    return pendingAt == null
        ? const KeepArrivingSoonSchedule()
        : const CancelArrivingSoonSchedule();
  }
  if (remindAt == null) {
    // Without a fresh estimate the app knows nothing better than what it
    // scheduled last, so the pending reminder stays where it is.
    return const KeepArrivingSoonSchedule();
  }
  final drift = pendingAt?.difference(remindAt).abs();
  return drift != null && drift <= _rescheduleThreshold
      ? const KeepArrivingSoonSchedule()
      : SetArrivingSoonSchedule(remindAt);
}

bool _isOnGroundAfterFlying(FlightTracking tracking) =>
    tracking.hasBeenAirborne && tracking.lastKnownOnGround == true;

/// The estimate a viewer would see as live; a frozen one carries the arrival of
/// a position that stopped coming in and must not trigger anything.
ArrivalEstimate? _freshEstimateOf(Flight flight, DateTime now) {
  final position = flight.tracking.latestPosition;
  if (position == null ||
      now.difference(position.timestamp) > maximumLivePositionAge) {
    return null;
  }
  return arrivalEstimateOf(flight);
}
