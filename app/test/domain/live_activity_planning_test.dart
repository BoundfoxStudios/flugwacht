import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/live_activity_planning.dart';
import 'package:flutter_test/flutter_test.dart';

const _departureDate = CalendarDate(2026, 3, 17);

final _beforeFlightDay = DateTime(2026, 3, 16, 12);
final _onFlightDay = DateTime(2026, 3, 17, 12);
final _afterFlightDay = DateTime(2026, 3, 19, 12);

FixPosition _position(DateTime timestamp, {bool onGround = false}) =>
    FixPosition(
      latitude: 49.875687,
      longitude: 7.888834,
      timestamp: timestamp,
      onGround: onGround,
    );

Flight _flight({
  bool isArmed = true,
  String? activityId,
  DateTime? reminderScheduledFor,
  DayTime? departureTime,
  FlightTracking tracking = const FlightTracking(),
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'LH433',
  departureDate: _departureDate,
  departureTime: departureTime,
  tracking: tracking,
  liveActivityArmed: isArmed,
  liveActivityId: activityId,
  liveActivityReminderScheduledFor: reminderScheduledFor,
);

LiveActivityAction _action({required Flight flight, DateTime? now}) =>
    planLiveActivityAction(flight: flight, now: now ?? _onFlightDay);

LiveActivityReminderSchedule _reminder({
  required Flight flight,
  bool isReminderEnabled = true,
  DateTime? now,
}) => planLiveActivityReminder(
  flight: flight,
  isReminderEnabled: isReminderEnabled,
  now: now ?? _onFlightDay,
);

void main() {
  group('activity', () {
    test('starts one for an armed flight waiting on its flight day', () {
      final action = _action(flight: _flight());
      expect(action, isA<StartLiveActivity>());
    });

    test('starts one for an armed flight that is being tracked', () {
      final action = _action(
        flight: _flight(
          tracking: FlightTracking(latestPosition: _position(_onFlightDay)),
        ),
      );
      expect(action, isA<StartLiveActivity>());
    });

    test('updates the activity that already runs', () {
      final action = _action(flight: _flight(activityId: 'activity-1'));
      expect(
        action,
        isA<UpdateLiveActivity>().having(
          (action) => action.activityId,
          'activityId',
          'activity-1',
        ),
      );
    });

    test('updates the activity while the position has gone stale', () {
      final action = _action(
        flight: _flight(
          activityId: 'activity-1',
          tracking: FlightTracking(
            latestPosition: _position(
              _onFlightDay.subtract(const Duration(hours: 1)),
            ),
          ),
        ),
      );
      expect(action, isA<UpdateLiveActivity>());
    });

    test('starts nothing before the flight day', () {
      final action = _action(flight: _flight(), now: _beforeFlightDay);
      expect(action, isA<KeepLiveActivity>());
    });

    test('starts nothing for a flight that is not armed', () {
      final action = _action(flight: _flight(isArmed: false));
      expect(action, isA<KeepLiveActivity>());
    });

    test('ends the activity of a flight that was disarmed', () {
      final action = _action(
        flight: _flight(isArmed: false, activityId: 'activity-1'),
      );
      expect(
        action,
        isA<EndLiveActivity>()
            .having((action) => action.activityId, 'activityId', 'activity-1')
            .having(
              (action) => action.dismissAfter,
              'dismissAfter',
              Duration.zero,
            ),
      );
    });

    test('lets a landed flight stand for the grace period', () {
      final action = _action(
        flight: _flight(
          activityId: 'activity-1',
          tracking: FlightTracking(
            latestPosition: _position(_onFlightDay, onGround: true),
            hasBeenAirborne: true,
            lastKnownOnGround: true,
          ),
        ),
      );
      expect(
        action,
        isA<EndLiveActivity>().having(
          (action) => action.dismissAfter,
          'dismissAfter',
          landedActivityGrace,
        ),
      );
    });

    test('starts nothing again once the landed activity is gone', () {
      final action = _action(
        flight: _flight(
          tracking: FlightTracking(
            latestPosition: _position(_onFlightDay, onGround: true),
            hasBeenAirborne: true,
            lastKnownOnGround: true,
          ),
        ),
      );
      expect(action, isA<KeepLiveActivity>());
    });

    test('ends the activity of a flight that was never seen', () {
      final action = _action(
        flight: _flight(activityId: 'activity-1'),
        now: _afterFlightDay,
      );
      expect(
        action,
        isA<EndLiveActivity>().having(
          (action) => action.dismissAfter,
          'dismissAfter',
          Duration.zero,
        ),
      );
    });
  });

  group('reminder', () {
    test('schedules it two hours before the stored departure', () {
      final schedule = _reminder(
        flight: _flight(departureTime: const DayTime(10, 0)),
        now: _beforeFlightDay,
      );
      expect(
        schedule,
        isA<SetLiveActivityReminder>().having(
          (schedule) => schedule.at,
          'at',
          DateTime(2026, 3, 17, 8),
        ),
      );
    });

    test('schedules it at the start of the flight day without a time', () {
      final schedule = _reminder(flight: _flight(), now: _beforeFlightDay);
      expect(
        schedule,
        isA<SetLiveActivityReminder>().having(
          (schedule) => schedule.at,
          'at',
          DateTime(2026, 3, 17),
        ),
      );
    });

    /// The lead time of a flight just after midnight reaches into the day
    /// before, where no activity could start yet.
    test('never schedules it before the flight day begins', () {
      final schedule = _reminder(
        flight: _flight(departureTime: const DayTime(1, 0)),
        now: _beforeFlightDay,
      );
      expect(
        schedule,
        isA<SetLiveActivityReminder>().having(
          (schedule) => schedule.at,
          'at',
          DateTime(2026, 3, 17),
        ),
      );
    });

    test('leaves a reminder that is pending in another time zone', () {
      final schedule = _reminder(
        flight: _flight(
          departureTime: const DayTime(10, 0),
          reminderScheduledFor: DateTime(2026, 3, 17, 8).toUtc(),
        ),
        now: _beforeFlightDay,
      );
      expect(schedule, isA<KeepLiveActivityReminder>());
    });

    test('leaves a reminder that is already scheduled for that moment', () {
      final schedule = _reminder(
        flight: _flight(
          departureTime: const DayTime(10, 0),
          reminderScheduledFor: DateTime(2026, 3, 17, 8),
        ),
        now: _beforeFlightDay,
      );
      expect(schedule, isA<KeepLiveActivityReminder>());
    });

    test('moves a reminder the departure time has moved away from', () {
      final schedule = _reminder(
        flight: _flight(
          departureTime: const DayTime(12, 0),
          reminderScheduledFor: DateTime(2026, 3, 17, 8),
        ),
        now: _beforeFlightDay,
      );
      expect(
        schedule,
        isA<SetLiveActivityReminder>().having(
          (schedule) => schedule.at,
          'at',
          DateTime(2026, 3, 17, 10),
        ),
      );
    });

    test('cancels the reminder of a flight that was disarmed', () {
      final schedule = _reminder(
        flight: _flight(
          isArmed: false,
          reminderScheduledFor: DateTime(2026, 3, 17, 8),
        ),
        now: _beforeFlightDay,
      );
      expect(schedule, isA<CancelLiveActivityReminder>());
    });

    test('schedules nothing while the setting is off', () {
      final schedule = _reminder(
        flight: _flight(),
        isReminderEnabled: false,
        now: _beforeFlightDay,
      );
      expect(schedule, isA<KeepLiveActivityReminder>());
    });

    test('cancels a pending reminder when the setting goes off', () {
      final schedule = _reminder(
        flight: _flight(reminderScheduledFor: DateTime(2026, 3, 17)),
        isReminderEnabled: false,
        now: _beforeFlightDay,
      );
      expect(schedule, isA<CancelLiveActivityReminder>());
    });

    test('cancels the reminder once its moment has passed', () {
      final schedule = _reminder(
        flight: _flight(
          departureTime: const DayTime(10, 0),
          reminderScheduledFor: DateTime(2026, 3, 17, 8),
        ),
      );
      expect(schedule, isA<CancelLiveActivityReminder>());
    });

    test('cancels the reminder while the activity already runs', () {
      final schedule = _reminder(
        flight: _flight(
          activityId: 'activity-1',
          reminderScheduledFor: DateTime(2026, 3, 17),
        ),
        now: _beforeFlightDay,
      );
      expect(schedule, isA<CancelLiveActivityReminder>());
    });

    test('cancels the reminder of a flight that has landed', () {
      final schedule = _reminder(
        flight: _flight(
          departureTime: const DayTime(23, 0),
          reminderScheduledFor: DateTime(2026, 3, 17, 21),
          tracking: FlightTracking(
            latestPosition: _position(_onFlightDay, onGround: true),
            hasBeenAirborne: true,
            lastKnownOnGround: true,
          ),
        ),
      );
      expect(schedule, isA<CancelLiveActivityReminder>());
    });
  });
}
