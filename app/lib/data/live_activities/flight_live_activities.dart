import '../../domain/flight.dart';
import '../../domain/live_activity_planning.dart';
import '../persistence/flight_repository.dart';
import 'live_activity_payload.dart';
import 'live_activity_service.dart';

/// Turns what the app learns about its flights into Live Activities: decides
/// with [planLiveActivityAction], talks to the system through the service and
/// remembers which card belongs to which flight.
class FlightLiveActivities {
  FlightLiveActivities({
    required this._repository,
    required this._service,
    this.clock = DateTime.now,
  });

  final FlightRepository _repository;
  final LiveActivityService _service;
  final DateTime Function() clock;

  /// The card this app run put up for a flight. The stored id only catches up
  /// once the write has travelled back through the flight stream, and a second
  /// pass in between would put a second card on the Lock Screen.
  final _activityIds = <int, String>{};

  Future<void> refreshAvailability() => _service.refreshAvailability();

  Future<void> flightsChanged(List<Flight> flights) async {
    for (final flight in flights) {
      await _apply(flight);
    }
  }

  /// Takes the cards of flights that are gone off the Lock Screen — their rows,
  /// and with them everything the app knew about their activities, are already
  /// deleted.
  Future<void> flightsRemoved(Iterable<Flight> flights) async {
    for (final flight in flights) {
      if (_runningActivityOf(flight) case final activityId?) {
        _activityIds.remove(flight.id);
        await _service.end(activityId);
      }
    }
  }

  /// Forgets the activities the system has ended on its own — it caps how long
  /// one runs, and the app only learns that by asking.
  Future<void> reconcile(List<Flight> flights) async {
    final running = await _service.runningActivityIds();
    for (final flight in flights) {
      final activityId = _runningActivityOf(flight);
      if (activityId != null && !running.contains(activityId)) {
        _activityIds.remove(flight.id);
        await _repository.setLiveActivityId(flight.id, null);
      }
    }
  }

  Future<void> _apply(Flight flight) async {
    final known = _runningActivityOf(flight);
    final action = planLiveActivityAction(
      flight: known == null ? flight : flight.copyWith(liveActivityId: known),
      now: clock(),
    );
    switch (action) {
      case KeepLiveActivity():
        return;
      case StartLiveActivity():
        // A card the system would refuse leaves the flight without one, and
        // the app must not remember an activity that never appeared.
        if (_service.availability.value != LiveActivityAvailability.enabled) {
          return;
        }
        final activityId = _activityIdOf(flight);
        _activityIds[flight.id] = activityId;
        await _put(activityId, flight);
        await _repository.setLiveActivityId(flight.id, activityId);
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
