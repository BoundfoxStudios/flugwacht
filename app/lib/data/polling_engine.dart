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
    this.clock = DateTime.now,
  });

  static const _tickInterval = Duration(seconds: 1);

  final FlightRepository _repository;

  /// One adapter per source, so each keeps its own rate limit.
  final Map<SourceId, SourceAdapter> _adapters;

  final SourceId Function() _activeSourceId;
  final AirlineDirectory _airlineDirectory;
  final FlightNotifier _notifier;
  final DateTime Function() clock;

  final _lastPollStarts = <int, DateTime>{};
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
    final goneIds = _flights
        .map((flight) => flight.id)
        .where((flightId) => !flights.any((flight) => flight.id == flightId));
    _flights = flights;
    final storedIds = flights.map((flight) => flight.id).toSet();
    _lastPollStarts.removeWhere((flightId, _) => !storedIds.contains(flightId));
    unawaited(_notifier.flightsRemoved(goneIds.toList()));
    if (_scheduler != null) {
      _pollDueFlights();
    }
  }

  void _pollDueFlights() {
    final now = clock();
    for (final flight in _flights) {
      final state = resolveFlightState(flight, now);
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
