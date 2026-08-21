import 'calendar_date.dart';
import 'day_time.dart';
import 'fix.dart';
import 'flight_day_window.dart';
import 'flight_notification.dart';
import 'flight_route.dart';

enum FlightLookupKind { flightNumber, registration, hexAddress }

/// Which clock the entered departure time belongs to: the origin airport's
/// local time — what the ticket says — or the device's own time.
enum DepartureTimeInterpretation { originLocal, device }

class Flight {
  const Flight({
    required this.id,
    required this.lookupKind,
    required this.lookupValue,
    required this.departureDate,
    this.departureTime,
    this.departureTimeInterpretation = DepartureTimeInterpretation.device,
    this.note,
    this.hexAddress,
    this.expectedCallsign,
    this.route,
    this.tracking = const FlightTracking(),
    this.notifications = const NotificationMarkers(),
    this.liveActivityArmed = false,
    this.liveActivityId,
    this.liveActivityReminderScheduledFor,
  });

  final int id;
  final FlightLookupKind lookupKind;
  final String lookupValue;
  final CalendarDate departureDate;
  final DayTime? departureTime;
  final DepartureTimeInterpretation departureTimeInterpretation;
  final String? note;
  final String? hexAddress;
  final String? expectedCallsign;
  final FlightRoute? route;
  final FlightTracking tracking;
  final NotificationMarkers notifications;

  /// Whether the user wants this flight on the Lock Screen on its flight day.
  final bool liveActivityArmed;

  /// The activity the system currently shows for this flight, if one runs.
  final String? liveActivityId;

  final DateTime? liveActivityReminderScheduledFor;

  Flight copyWith({
    int? id,
    FlightLookupKind? lookupKind,
    String? lookupValue,
    CalendarDate? departureDate,
    DayTime? departureTime,
    DepartureTimeInterpretation? departureTimeInterpretation,
    String? note,
    String? hexAddress,
    String? expectedCallsign,
    FlightRoute? route,
    FlightTracking? tracking,
    NotificationMarkers? notifications,
    bool? liveActivityArmed,
    String? liveActivityId,
    DateTime? liveActivityReminderScheduledFor,
  }) => Flight(
    id: id ?? this.id,
    lookupKind: lookupKind ?? this.lookupKind,
    lookupValue: lookupValue ?? this.lookupValue,
    departureDate: departureDate ?? this.departureDate,
    departureTime: departureTime ?? this.departureTime,
    departureTimeInterpretation:
        departureTimeInterpretation ?? this.departureTimeInterpretation,
    note: note ?? this.note,
    hexAddress: hexAddress ?? this.hexAddress,
    expectedCallsign: expectedCallsign ?? this.expectedCallsign,
    route: route ?? this.route,
    tracking: tracking ?? this.tracking,
    notifications: notifications ?? this.notifications,
    liveActivityArmed: liveActivityArmed ?? this.liveActivityArmed,
    liveActivityId: liveActivityId ?? this.liveActivityId,
    liveActivityReminderScheduledFor:
        liveActivityReminderScheduledFor ??
        this.liveActivityReminderScheduledFor,
  );
}

class FlightTracking {
  const FlightTracking({
    this.latestPosition,
    this.hasBeenAirborne = false,
    this.lastKnownOnGround,
    this.firstAirborneAt,
  });

  final FixPosition? latestPosition;
  final bool hasBeenAirborne;
  final bool? lastKnownOnGround;

  /// When the flight was first seen off the ground, the anchor a progress bar
  /// runs from.
  final DateTime? firstAirborneAt;

  FlightTracking withFix(Fix fix, FlightDayWindow window) {
    final position = fix.position;
    if (position == null || position.timestamp.isBefore(window.start)) {
      return this;
    }
    return FlightTracking(
      latestPosition: position,
      hasBeenAirborne: hasBeenAirborne || position.onGround == false,
      lastKnownOnGround: position.onGround ?? lastKnownOnGround,
      firstAirborneAt:
          firstAirborneAt ??
          (position.onGround == false ? position.timestamp : null),
    );
  }
}
