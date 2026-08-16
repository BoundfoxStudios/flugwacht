import '../domain/flight.dart';
import '../domain/flight_notification.dart';
import '../domain/notification_planning.dart';
import 'flight_repository.dart';
import 'notification_service.dart';
import 'notification_setting.dart';

typedef FlightNotificationText = ({String title, String body});

/// Words a notification in the app's language; built where the localizations
/// live, because nothing down here knows them.
typedef FlightNotificationCopy =
    FlightNotificationText Function(FlightNotification kind, Flight flight);

/// Turns what the polling engine learns about a flight into notifications:
/// decides with [planNotifications], delivers through the service and writes
/// the markers that keep every notification a one-off.
class FlightNotifier {
  FlightNotifier({
    required this._repository,
    required this._service,
    required this._setting,
    required this._copy,
    this.clock = DateTime.now,
  });

  final FlightRepository _repository;
  final NotificationService _service;
  final NotificationSetting _setting;
  final FlightNotificationCopy _copy;
  final DateTime Function() clock;

  /// When the system is due to deliver a flight's arrival reminder, so a
  /// changed estimate can move it and a landing can call it off.
  final _pendingArrivingSoonAt = <int, DateTime>{};

  Future<void> trackingChanged(Flight flight, FlightTracking tracking) async {
    // A marker says the user was told. Nothing reaches them through a service
    // the device could not set up, so nothing may be marked either.
    if (_service.permission.value == NotificationPermission.unavailable) {
      return;
    }
    final updated = flight.copyWith(tracking: tracking);
    final plan = planNotifications(
      flight: updated,
      previousTracking: flight.tracking,
      pendingArrivingSoonAt: _pendingArrivingSoonAt[flight.id],
      isEnabled: _setting.isEnabled,
      now: clock(),
    );
    for (final kind in plan.events) {
      await _deliver(kind, updated);
    }
    await _applySchedule(plan.schedule, updated);
  }

  /// Takes the reminders of flights that are gone off the system's hands —
  /// unconditionally, because a reminder scheduled in an earlier run outlives
  /// what this one remembers.
  Future<void> flightsRemoved(Iterable<int> flightIds) async {
    for (final flightId in flightIds) {
      _pendingArrivingSoonAt.remove(flightId);
      await _service.cancel(
        FlightNotification.arrivingSoon,
        flightId: flightId,
      );
    }
  }

  /// A reminder whose moment passed while the app was away reached the user
  /// through the system, so it counts as delivered.
  Future<void> reconcileDeliveredReminders() async {
    final now = clock();
    final delivered = _pendingArrivingSoonAt.entries
        .where((entry) => !now.isBefore(entry.value))
        .map((entry) => entry.key)
        .toList();
    for (final flightId in delivered) {
      _pendingArrivingSoonAt.remove(flightId);
      await _repository.markNotificationDelivered(
        flightId,
        FlightNotification.arrivingSoon,
        now,
      );
    }
  }

  Future<void> _deliver(FlightNotification kind, Flight flight) async {
    final text = _copy(kind, flight);
    await _service.show(
      kind,
      flightId: flight.id,
      title: text.title,
      body: text.body,
    );
    await _repository.markNotificationDelivered(flight.id, kind, clock());
  }

  Future<void> _applySchedule(
    ArrivingSoonSchedule schedule,
    Flight flight,
  ) async {
    switch (schedule) {
      case KeepArrivingSoonSchedule():
        return;
      case CancelArrivingSoonSchedule():
        _pendingArrivingSoonAt.remove(flight.id);
        await _service.cancel(
          FlightNotification.arrivingSoon,
          flightId: flight.id,
        );
      case SetArrivingSoonSchedule(:final at):
        _pendingArrivingSoonAt[flight.id] = at;
        final text = _copy(FlightNotification.arrivingSoon, flight);
        await _service.schedule(
          FlightNotification.arrivingSoon,
          flightId: flight.id,
          title: text.title,
          body: text.body,
          at: at,
        );
    }
  }
}
