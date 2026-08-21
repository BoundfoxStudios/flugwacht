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

  Future<void> flightsChanged(List<Flight> flights) async {
    for (final flight in flights) {
      await _apply(
        planLiveActivityAction(flight: flight, now: clock()),
        flight,
      );
    }
  }

  /// Takes the cards of flights that are gone off the Lock Screen — their rows,
  /// and with them everything the app knew about their activities, are already
  /// deleted.
  Future<void> flightsRemoved(Iterable<Flight> flights) async {
    for (final flight in flights) {
      if (flight.liveActivityId case final activityId?) {
        await _service.end(activityId);
      }
    }
  }

  /// Forgets the activities the system has ended on its own — it caps how long
  /// one runs, and the app only learns that by asking.
  Future<void> reconcile(List<Flight> flights) async {
    final running = await _service.runningActivityIds();
    for (final flight in flights) {
      final activityId = flight.liveActivityId;
      if (activityId != null && !running.contains(activityId)) {
        await _repository.setLiveActivityId(flight.id, null);
      }
    }
  }

  Future<void> _apply(LiveActivityAction action, Flight flight) async {
    switch (action) {
      case KeepLiveActivity():
        return;
      case StartLiveActivity():
        // A card the system would refuse leaves the flight without one, and
        // the app must not remember an activity that never appeared.
        if (!await _service.areActivitiesEnabled()) {
          return;
        }
        final activityId = _activityIdOf(flight);
        await _put(activityId, flight);
        await _repository.setLiveActivityId(flight.id, activityId);
      case UpdateLiveActivity(:final activityId):
        await _put(activityId, flight);
      case EndLiveActivity(:final activityId, :final dismissAfter):
        final dismissAt = dismissAfter > Duration.zero
            ? clock().add(dismissAfter)
            : null;
        // A card that stays a while shows what became of the flight first.
        if (dismissAt != null) {
          await _put(activityId, flight);
        }
        await _service.end(activityId, dismissAt: dismissAt);
        await _repository.setLiveActivityId(flight.id, null);
    }
  }

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
