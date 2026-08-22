import '../../domain/flight.dart';
import '../../domain/live_activity_planning.dart';
import '../notifications/notification_service.dart';
import '../persistence/flight_repository.dart';
import '../settings/live_activity_setting.dart';
import 'live_activity_payload.dart';
import 'live_activity_service.dart';

/// What the flight-day reminder says; built where the localizations live,
/// because nothing down here knows them.
typedef LiveActivityReminderCopy =
    ({String title, String body}) Function(Flight flight);

/// Turns what the app learns about its flights into Live Activities: decides
/// with [planLiveActivityAction], talks to the system through the service and
/// remembers which card belongs to which flight.
class FlightLiveActivities {
  FlightLiveActivities({
    required this._repository,
    required this._service,
    required this._notifications,
    required this._setting,
    required this._copy,
    this.clock = DateTime.now,
  });

  final FlightRepository _repository;
  final LiveActivityService _service;
  final NotificationService _notifications;
  final LiveActivitySetting _setting;
  final LiveActivityReminderCopy _copy;
  final DateTime Function() clock;

  /// The card this app run put up for a flight. The stored id only catches up
  /// once the write has travelled back through the flight stream, and a second
  /// pass in between would put a second card on the Lock Screen.
  final _activityIds = <int, String>{};

  /// Passes run one after another, never interleaved. A reconcile that lands
  /// while a card is still being created asks the system about an activity
  /// that does not exist yet, forgets it, and the next pass starts a second
  /// one — the app open inside the flight-day window does exactly that.
  Future<void> _passes = Future<void>.value();

  Future<void> refreshAvailability() => _inTurn(_service.refreshAvailability);

  Future<void> flightsChanged(List<Flight> flights) =>
      _inTurn(() => _applyToEach(flights));

  Future<void> _inTurn(Future<void> Function() pass) {
    final next = _passes.then((_) => pass());
    _passes = next.catchError((Object _) {});
    return next;
  }

  Future<void> _applyToEach(List<Flight> flights) async {
    for (final flight in flights) {
      // One card the system refuses must not cost the other flights theirs,
      // and must not take the polling run down with it.
      try {
        await _apply(flight);
        await _applyReminder(flight);
      } on Exception {
        continue;
      }
    }
  }

  /// Takes the cards of flights that are gone off the Lock Screen — their rows,
  /// and with them everything the app knew about their activities, are already
  /// deleted.
  Future<void> flightsRemoved(Iterable<Flight> flights) => _inTurn(() async {
    for (final flight in flights) {
      if (_runningActivityOf(flight) case final activityId?) {
        _activityIds.remove(flight.id);
        await _service.end(activityId);
      }
      // Unconditionally: the row that knew about a pending reminder is gone
      // either way, so only the system still has it.
      await _notifications.cancelLiveActivityReminder(flightId: flight.id);
    }
  });

  /// Forgets the activities the system has ended on its own — it caps how long
  /// one runs, and the app only learns that by asking.
  Future<void> reconcile(List<Flight> flights) => _inTurn(() async {
    for (final flight in flights) {
      final activityId = _runningActivityOf(flight);
      if (activityId == null || await _service.isRunning(activityId)) {
        continue;
      }
      // Only forget the card this call asked about: a pass that started a
      // fresh one in the meantime must keep it.
      if (_runningActivityOf(flight) == activityId) {
        _activityIds.remove(flight.id);
        await _repository.setLiveActivityId(flight.id, null);
      }
    }
  });

  Future<void> _apply(Flight flight) async {
    final known = _runningActivityOf(flight);
    final action = planLiveActivityAction(
      flight: known == null ? flight : flight.copyWith(liveActivityId: known),
      now: clock(),
    );
    // A card the system would refuse leaves the flight without one, and the
    // app must not remember an activity that never appeared. Ending still
    // goes through: a card from before the switch was flipped has to go.
    if (_service.availability.value != LiveActivityAvailability.enabled &&
        action is! EndLiveActivity) {
      return;
    }
    switch (action) {
      case KeepLiveActivity():
        return;
      case StartLiveActivity():
        final activityId = _activityIdOf(flight);
        _activityIds[flight.id] = activityId;
        // Written before the card exists: a put that throws would otherwise
        // leave the id in memory only, and the next app run would start a
        // second card it can no longer reach the first one through. An id
        // whose card never appeared is cleared by the next reconcile.
        await _repository.setLiveActivityId(flight.id, activityId);
        await _put(activityId, flight);
      case UpdateLiveActivity(:final activityId):
        await _put(activityId, flight);
      case EndLiveActivity(:final activityId, :final dismissAfter):
        final dismissAt = dismissAfter > Duration.zero
            ? clock().add(dismissAfter)
            : null;
        _activityIds.remove(flight.id);
        // A card that stays a while shows what became of the flight first.
        if (dismissAt != null) {
          await _put(activityId, flight);
        }
        await _service.end(activityId, dismissAt: dismissAt);
        await _repository.setLiveActivityId(flight.id, null);
    }
  }

  Future<void> _applyReminder(Flight flight) async {
    // A reminder nothing would deliver must not be remembered as pending.
    final isNotifiable =
        _notifications.permission.value == NotificationPermission.granted;
    final known = _runningActivityOf(flight);
    final schedule = planLiveActivityReminder(
      flight: known == null ? flight : flight.copyWith(liveActivityId: known),
      isReminderEnabled: isNotifiable && _setting.remindsOnFlightDay.value,
      now: clock(),
    );
    switch (schedule) {
      case KeepLiveActivityReminder():
        return;
      case CancelLiveActivityReminder():
        await _repository.setLiveActivityReminderSchedule(flight.id, null);
        await _notifications.cancelLiveActivityReminder(flightId: flight.id);
      case SetLiveActivityReminder(:final at):
        await _repository.setLiveActivityReminderSchedule(flight.id, at);
        final text = _copy(flight);
        await _notifications.scheduleLiveActivityReminder(
          flightId: flight.id,
          title: text.title,
          body: text.body,
          at: at,
        );
    }
  }

  String? _runningActivityOf(Flight flight) =>
      _activityIds[flight.id] ?? flight.liveActivityId;

  Future<void> _put(String activityId, Flight flight) async {
    final now = clock();
    await _service.put(
      activityId,
      data: liveActivityPayloadOf(flight, now),
      staleIn: liveActivityStaleIn(flight, now),
    );
  }

  /// Unique per start: a card the system already dismissed must not have its
  /// identifier reused by the next one.
  String _activityIdOf(Flight flight) =>
      'flight-${flight.id}-${clock().millisecondsSinceEpoch}';
}
