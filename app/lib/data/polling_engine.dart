import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/fix.dart';
import '../domain/flight.dart';
import '../domain/flight_day_window.dart';
import '../domain/flight_number.dart';
import '../domain/flight_state.dart';
import '../domain/poll_planning.dart';
import '../domain/source_id.dart';
import 'adapters/lookup_result.dart';
import 'adapters/source_adapter.dart';
import 'live_activities/flight_live_activities.dart';
import 'lookup/airline_directory.dart';
import 'notifications/flight_notifier.dart';
import 'persistence/flight_repository.dart';

/// Polls the stored flights while the app is in the foreground and writes what
/// the source answers back into the repository.
class PollingEngine with WidgetsBindingObserver {
  PollingEngine({
    required this._repository,
    required this._adapters,
    required this._activeSourceId,
    required this._airlineDirectory,
    required this._notifier,
    required this._liveActivities,
    required this._onFlightLanded,
    this.clock = DateTime.now,
  });

  static const _tickInterval = Duration(seconds: 1);

  final FlightRepository _repository;

  /// One adapter per source, so each keeps its own rate limit.
  final Map<SourceId, SourceAdapter> _adapters;

  final SourceId Function() _activeSourceId;
  final AirlineDirectory _airlineDirectory;
  final FlightNotifier _notifier;
  final FlightLiveActivities _liveActivities;
  final Future<void> Function() _onFlightLanded;
  final DateTime Function() clock;

  final _lastPollStarts = <int, DateTime>{};
  final _lastStates = <int, FlightState>{};
  final _runningLookups = <int>{};
  var _flights = const <Flight>[];
  var _wantsPolling = false;
  StreamSubscription<List<Flight>>? _subscription;
  Timer? _scheduler;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _subscription = _repository.watchFlights().listen(_onFlights);
    _resumePolling();
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _wantsPolling = false;
    _stopScheduler();
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumePolling();
    } else {
      _wantsPolling = false;
      _stopScheduler();
    }
  }

  /// Whatever the system delivered while the app was away goes on record
  /// first: a poll that ran before that would plan around notifications the
  /// user has already had.
  void _resumePolling() {
    _wantsPolling = true;
    unawaited(_reconcileThenPoll());
  }

  Future<void> _reconcileThenPoll() async {
    await _notifier.reconcileDeliveredReminders();
    // Live Activities are switched off in the system settings, so the app only
    // learns about it on the way back. iOS also ends a card on its own once it
    // hits the runtime limit, which this app run is the first chance to see.
    // A platform that refuses any of it costs the user their cards, never the
    // polling this run exists for.
    try {
      await _liveActivities.refreshAvailability();
      await _liveActivities.reconcile(_flights);
      await _liveActivities.flightsChanged(_flights);
    } on Exception {
      // The next resume asks again.
    }
    if (_wantsPolling) {
      _startScheduler();
    }
  }

  void _startScheduler() {
    _scheduler?.cancel();
    _scheduler = Timer.periodic(_tickInterval, (_) => _pollDueFlights());
    _pollDueFlights();
  }

  void _stopScheduler() {
    _scheduler?.cancel();
    _scheduler = null;
  }

  bool get _isPolling => _scheduler != null;

  void _onFlights(List<Flight> flights) {
    final gone = _flights
        .where((flight) => !flights.any((stored) => stored.id == flight.id))
        .toList();
    _flights = flights;
    final storedIds = flights.map((flight) => flight.id).toSet();
    _lastPollStarts.removeWhere((flightId, _) => !storedIds.contains(flightId));
    _lastStates.removeWhere((flightId, _) => !storedIds.contains(flightId));
    unawaited(
      _notifier.flightsRemoved(gone.map((flight) => flight.id).toList()),
    );
    unawaited(_liveActivities.flightsRemoved(gone));
    unawaited(_liveActivities.flightsChanged(flights));
    if (_scheduler != null) {
      _pollDueFlights();
    }
  }

  void _pollDueFlights() {
    final now = clock();
    var hasStateChanged = false;
    for (final flight in _flights) {
      final state = resolveFlightState(flight, now);
      if (_lastStates[flight.id] case final previous? when previous != state) {
        hasStateChanged = true;
      }
      _lastStates[flight.id] = state;
      if (!isPollable(state)) {
        _lastPollStarts.remove(flight.id);
        continue;
      }
      if (_runningLookups.contains(flight.id)) {
        continue;
      }
      final lastPollStart = _lastPollStarts[flight.id];
      if (lastPollStart != null &&
          now.difference(lastPollStart) < pollInterval(flight, state, now)) {
        continue;
      }
      _lastPollStarts[flight.id] = now;
      unawaited(_pollFlight(flight));
    }
    // A flight falling silent is written nowhere: its last position simply
    // ages past the moment it stands for. Nothing but the clock moves it, so
    // nothing but the clock can tell the card about it.
    if (hasStateChanged) {
      unawaited(_liveActivities.flightsChanged(_flights));
    }
  }

  Future<void> _pollFlight(Flight flight) async {
    _runningLookups.add(flight.id);
    try {
      final adapter = _adapters[_activeSourceId()]!;
      final window = FlightDayWindow.forDepartureDate(flight.departureDate);
      switch (planPollQuery(flight, _callsignCandidates(flight))) {
        case HexAddressPollQuery(:final hexAddress):
          await _applyOutcome(
            flight,
            _outcomeOf(
              await adapter.lookupByHexAddress(hexAddress),
              flight,
              HexAddressPollQuery(hexAddress),
              window,
            ),
          );
        case RegistrationPollQuery(:final registration):
          await _applyOutcome(
            flight,
            _outcomeOf(
              await adapter.lookupByRegistration(registration),
              flight,
              RegistrationPollQuery(registration),
              window,
            ),
          );
        case CallsignSearchPollQuery(:final candidates):
          for (final candidate in candidates) {
            if (!_isPolling) {
              return;
            }
            final outcome = _outcomeOf(
              await adapter.lookupByCallsign(candidate),
              flight,
              CallsignSearchPollQuery([candidate]),
              window,
            );
            if (outcome is PollNoData || outcome is PollAwaitsDeparture) {
              continue;
            }
            await _applyOutcome(flight, outcome);
            return;
          }
      }
    } finally {
      _runningLookups.remove(flight.id);
    }
  }

  List<String> _callsignCandidates(Flight flight) {
    if (flight.lookupKind != FlightLookupKind.flightNumber) {
      return const [];
    }
    final flightNumber = FlightNumber.tryParse(flight.lookupValue);
    return flightNumber == null
        ? const []
        : _airlineDirectory.callsignCandidates(flightNumber);
  }

  PollOutcome _outcomeOf(
    LookupResult result,
    Flight flight,
    PollQuery query,
    FlightDayWindow window,
  ) => switch (result) {
    LookupSuccess(:final fixes) => applyLookup(
      flight: flight,
      query: query,
      fixes: fixes,
      window: window,
      now: clock(),
    ),
    LookupNetworkFailure() ||
    LookupStatusFailure() ||
    LookupMalformedPayload() => const PollNoData(),
  };

  Future<void> _applyOutcome(Flight flight, PollOutcome outcome) async {
    if (!_isPolling) {
      return;
    }
    switch (outcome) {
      case PollNoData() || PollAwaitsDeparture():
        return;
      case PollIdentityAdopted(:final identity):
        await _writeIdentity(flight, identity);
      case PollIdentityRejected():
        if (flight.lookupKind == FlightLookupKind.flightNumber) {
          await _repository.updateIdentity(
            flight.id,
            hexAddress: null,
            expectedCallsign: flight.expectedCallsign,
          );
        }
      case PollAdoptionDisproved():
        await _repository.updateTracking(flight.id, const FlightTracking());
        await _repository.updateIdentity(
          flight.id,
          hexAddress: flight.hexAddress,
          expectedCallsign: null,
        );
        await _repository.clearTrail(flight.id);
        await _repository.resetNotificationMarkers(flight.id);
        await _notifier.adoptionDisproved(flight.id);
      case PollFixApplied(
        :final tracking,
        :final sourceId,
        :final trailPosition,
        :final adoptedIdentity,
      ):
        await _repository.updateTracking(flight.id, tracking);
        await _notifier.trackingChanged(flight, tracking);
        await _appendTrailPoint(flight, trailPosition, sourceId);
        if (adoptedIdentity != null) {
          await _writeIdentity(flight, adoptedIdentity);
        }
        // Once landed the flight is no longer pollable, so no later fix can
        // reach this line and report the same landing twice.
        if (isOnGroundAfterFlying(tracking)) {
          await _onFlightLanded();
        }
    }
  }

  Future<void> _writeIdentity(Flight flight, AdoptedIdentity identity) =>
      _repository.updateIdentity(
        flight.id,
        hexAddress: identity.hexAddress ?? flight.hexAddress,
        expectedCallsign: identity.callsign,
      );

  Future<void> _appendTrailPoint(
    Flight flight,
    FixPosition? trailPosition,
    SourceId sourceId,
  ) async {
    if (trailPosition != null) {
      await _repository.appendTrailPoint(flight.id, trailPosition, sourceId);
    }
  }
}
