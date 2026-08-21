import 'departure_time.dart';
import 'flight.dart';
import 'flight_day_window.dart';
import 'flight_state.dart';

/// How long a landed flight stays on the Lock Screen before the system takes
/// its card away.
const landedActivityGrace = Duration(minutes: 30);

/// How far ahead of the scheduled departure the flight-day reminder fires —
/// early enough to start the activity before boarding.
const _reminderLeadTime = Duration(hours: 2);

/// What should happen to the flight's Live Activity.
sealed class LiveActivityAction {
  const LiveActivityAction();
}

class KeepLiveActivity extends LiveActivityAction {
  const KeepLiveActivity();
}

class StartLiveActivity extends LiveActivityAction {
  const StartLiveActivity();
}

class UpdateLiveActivity extends LiveActivityAction {
  const UpdateLiveActivity(this.activityId);

  final String activityId;
}

class EndLiveActivity extends LiveActivityAction {
  const EndLiveActivity(this.activityId, {required this.dismissAfter});

  final String activityId;

  /// How long the card stays before the system dismisses it.
  final Duration dismissAfter;
}

/// What should happen to the local notification that offers to start the
/// activity on the flight day.
sealed class LiveActivityReminderSchedule {
  const LiveActivityReminderSchedule();
}

class KeepLiveActivityReminder extends LiveActivityReminderSchedule {
  const KeepLiveActivityReminder();
}

class SetLiveActivityReminder extends LiveActivityReminderSchedule {
  const SetLiveActivityReminder(this.at);

  final DateTime at;
}

class CancelLiveActivityReminder extends LiveActivityReminderSchedule {
  const CancelLiveActivityReminder();
}

/// What a flight's facts mean for its Live Activity, derived from the flight
/// alone so nothing about it depends on the platform.
LiveActivityAction planLiveActivityAction({
  required Flight flight,
  required DateTime now,
}) {
  final activityId = flight.liveActivityId;
  if (!flight.liveActivityArmed) {
    return activityId == null
        ? const KeepLiveActivity()
        : EndLiveActivity(activityId, dismissAfter: Duration.zero);
  }
  return switch (resolveFlightState(flight, now)) {
    // The flight day is running and the flight has something to show; outside
    // it a card would say nothing and only burn the system's runtime limit.
    FlightState.waiting || FlightState.live || FlightState.noSignal =>
      activityId == null
          ? const StartLiveActivity()
          : UpdateLiveActivity(activityId),
    // A landed card is the one the user still wants to look at.
    FlightState.ended =>
      activityId == null
          ? const KeepLiveActivity()
          : EndLiveActivity(activityId, dismissAfter: landedActivityGrace),
    FlightState.planned || FlightState.missed =>
      activityId == null
          ? const KeepLiveActivity()
          : EndLiveActivity(activityId, dismissAfter: Duration.zero),
  };
}

/// When the app should offer to start the flight's activity, for the flight
/// days the user is not looking at their phone.
LiveActivityReminderSchedule planLiveActivityReminder({
  required Flight flight,
  required bool isReminderEnabled,
  required DateTime now,
}) {
  final state = resolveFlightState(flight, now);
  final pendingAt = flight.liveActivityReminderScheduledFor;
  final remindAt = _reminderMoment(flight);
  final wantsReminder =
      flight.liveActivityArmed &&
      isReminderEnabled &&
      flight.liveActivityId == null &&
      state != FlightState.ended &&
      state != FlightState.missed &&
      remindAt.isAfter(now);
  if (!wantsReminder) {
    return pendingAt == null
        ? const KeepLiveActivityReminder()
        : const CancelLiveActivityReminder();
  }
  return pendingAt == remindAt
      ? const KeepLiveActivityReminder()
      : SetLiveActivityReminder(remindAt);
}

/// The moment the activity could first start: shortly before the departure the
/// user entered, or the start of the flight day when they entered none.
DateTime _reminderMoment(Flight flight) {
  final departure = departureInstantOf(flight);
  return departure == null
      ? FlightDayWindow.forDepartureDate(flight.departureDate).start
      : departure.subtract(_reminderLeadTime);
}
