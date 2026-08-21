import '../../domain/flight.dart';
import '../../domain/flight_notification.dart';
import '../../domain/notification_planning.dart';
import '../persistence/flight_repository.dart';
import '../settings/notification_setting.dart';
import 'notification_service.dart';

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
      pendingArrivingSoonAt: updated.notifications.arrivingSoonScheduledFor,
      isEnabled: _setting.isEnabled,
      now: clock(),
    );
    for (final kind in plan.events) {
      await _deliver(kind, updated);
    }
    await _applySchedule(plan.schedule, updated);
  }

  /// Takes the reminders of flights that are gone off the system's hands —
  /// unconditionally, because their rows, and with them everything the app
  /// knew about their reminders, are already deleted.
  Future<void> flightsRemoved(Iterable<int> flightIds) async {
    for (final flightId in flightIds) {
      await _service.cancel(
        FlightNotification.arrivingSoon,
        flightId: flightId,
      );
    }
  }

  /// A disproved contact takes its pending arrival reminder with it, so the
  /// real leg can schedule its own.
  Future<void> adoptionDisproved(int flightId) =>
      _service.cancel(FlightNotification.arrivingSoon, flightId: flightId);

  /// A reminder whose moment passed while the app was away reached the user
  /// through the system, so it counts as delivered.
  Future<void> reconcileDeliveredReminders() =>
      _repository.markDueRemindersDelivered(clock());

  /// Claims the notification before showing it: a poll that started with an
  /// older copy of the flight still carries the open marker, and only the call
  /// that closes it may reach the user.
  Future<void> _deliver(FlightNotification kind, Flight flight) async {
    final isClaimed = await _repository.claimNotification(
      flight.id,
      kind,
      clock(),
    );
    if (!isClaimed) {
      return;
    }
    final text = _copy(kind, flight);
    await _service.show(
      kind,
      flightId: flight.id,
      title: text.title,
      body: text.body,
    );
  }

  Future<void> _applySchedule(
    ArrivingSoonSchedule schedule,
    Flight flight,
  ) async {
    switch (schedule) {
      case KeepArrivingSoonSchedule():
        return;
      case CancelArrivingSoonSchedule():
        await _repository.setArrivingSoonSchedule(flight.id, null);
        await _service.cancel(
          FlightNotification.arrivingSoon,
          flightId: flight.id,
        );
      case SetArrivingSoonSchedule(:final at):
        await _repository.setArrivingSoonSchedule(flight.id, at);
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
