import 'dart:async';
import 'dart:math';

import 'package:signals/signals.dart';

import '../../data/persistence/flight_repository.dart';
import '../../domain/trail_point.dart';
import '../map_selection.dart';
import 'flight_list.dart';
import 'list_sections.dart';

/// The flights the map can show — those with a position, i.e. live or without
/// signal — together with the selection that markers, trail and camera follow.
class MapFlights {
  MapFlights({
    required FlightRepository repository,
    required this.selection,
    DateTime Function() clock = DateTime.now,
  }) : _repository = repository,
       _flightList = FlightList(repository: repository, clock: clock) {
    _stopReconcilingSelection = effect(_reconcileSelection);
    _stopWatchingTrail = effect(_watchTrail);
  }

  /// Owned by the router, so the list can select a flight for the map.
  final MapSelection selection;

  final FlightRepository _repository;
  final FlightList _flightList;

  late final flights = computed<List<FlightListEntry>>(
    () => _flightList.sections.value?.active ?? const [],
  );

  Signal<int?> get selectedId => selection.flightId;

  late final selected = computed<FlightListEntry?>(() {
    final id = selectedId.value;
    final matches = flights.value.where((entry) => entry.flight.id == id);
    return matches.isEmpty ? null : matches.first;
  });

  final trail = signal<List<TrailPoint>>(const []);

  var _knownIds = const <int>[];
  StreamSubscription<List<TrailPoint>>? _trailSubscription;
  late final EffectCleanup _stopReconcilingSelection;
  late final EffectCleanup _stopWatchingTrail;

  void dispose() {
    _stopReconcilingSelection();
    _stopWatchingTrail();
    unawaited(_trailSubscription?.cancel());
    trail.dispose();
    selected.dispose();
    flights.dispose();
    _flightList.dispose();
  }

  void _reconcileSelection() {
    final ids = [for (final entry in flights.value) entry.flight.id];
    final next = nextSelectedFlightId(
      previousIds: _knownIds,
      currentIds: ids,
      selectedId: selectedId.peek(),
    );
    _knownIds = ids;
    selectedId.value = next;
  }

  void _watchTrail() {
    final id = selectedId.value;
    unawaited(_trailSubscription?.cancel());
    _trailSubscription = null;
    trail.value = const [];
    if (id == null) {
      return;
    }
    _trailSubscription = _repository
        .watchTrail(id)
        .listen((points) => trail.value = points);
  }
}

/// The flight the map selects once the set of shown flights changes: the
/// selected one while it is still there, otherwise whichever flight took its
/// place in the order.
int? nextSelectedFlightId({
  required List<int> previousIds,
  required List<int> currentIds,
  required int? selectedId,
}) {
  if (currentIds.isEmpty) {
    return null;
  }
  if (selectedId != null && currentIds.contains(selectedId)) {
    return selectedId;
  }
  final previousIndex = selectedId == null
      ? -1
      : previousIds.indexOf(selectedId);
  return previousIndex < 0
      ? currentIds.first
      : currentIds[min(previousIndex, currentIds.length - 1)];
}
