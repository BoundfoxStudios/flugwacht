import 'dart:async';

import 'package:signals/signals.dart';

import '../../data/flight_repository.dart';
import '../../domain/flight.dart';
import 'list_sections.dart';

/// Watches the stored flights and re-derives their states once a minute, so a
/// planned flight turns into a waiting one without a repository event.
class FlightList {
  FlightList({required FlightRepository repository, this.clock = DateTime.now})
    : _repository = repository {
    _subscription = repository.watchFlights().listen(
      (flights) => _flights.value = flights,
    );
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  static const _tickInterval = Duration(minutes: 1);

  final FlightRepository _repository;
  final DateTime Function() clock;

  late final now = signal(clock());

  /// Null until the repository has emitted for the first time.
  late final sections = computed<FlightListSections?>(() {
    final flights = _flights.value;
    return flights == null ? null : groupFlights(flights, now.value);
  });

  final _flights = signal<List<Flight>?>(null);
  late final StreamSubscription<List<Flight>> _subscription;
  late final Timer _ticker;

  void dispose() {
    _ticker.cancel();
    unawaited(_subscription.cancel());
    sections.dispose();
    _flights.dispose();
    now.dispose();
  }

  void _onTick() {
    now.value = clock();
    unawaited(_repository.deleteExpiredFlights(now.value));
  }
}
