import 'dart:async';

import 'package:signals/signals.dart';

import '../../data/lookup/airline_directory.dart';
import '../../data/lookup/route_lookup.dart';
import '../../domain/flight.dart';
import '../../domain/flight_number.dart';
import '../../domain/flight_route.dart';
import 'new_flight_form.dart';

sealed class FlightPreviewState {
  const FlightPreviewState();
}

class FlightPreviewHidden extends FlightPreviewState {
  const FlightPreviewHidden();
}

class FlightPreviewFound extends FlightPreviewState {
  const FlightPreviewFound({required this.callsign, required this.route});

  final String callsign;
  final FlightRoute route;
}

class FlightPreviewRouteUnknown extends FlightPreviewState {
  const FlightPreviewRouteUnknown();
}

/// Resolves the route of the entered flight number once the typing rests, and
/// keeps only the result the current input asked for.
class NewFlightPreview {
  NewFlightPreview({
    required this._form,
    required this._airlineDirectory,
    required this._routeLookup,
    this.debounce = const Duration(milliseconds: 400),
  }) {
    _stopWatchingForm = effect(_onFormChanged);
  }

  final NewFlightForm _form;
  final AirlineDirectory _airlineDirectory;
  final RouteLookup _routeLookup;

  /// How long the typing has to rest before the route lookup runs.
  final Duration debounce;

  final state = signal<FlightPreviewState>(const FlightPreviewHidden());

  late final EffectCleanup _stopWatchingForm;
  Timer? _pendingLookup;
  String _requestedInput = '';

  void dispose() {
    _pendingLookup?.cancel();
    _stopWatchingForm();
    state.dispose();
  }

  void _onFormChanged() {
    final input = _form.inputFor(FlightLookupKind.flightNumber).value;
    final isFlightNumberKind =
        _form.lookupKind.value == FlightLookupKind.flightNumber;
    _requestedInput = input;
    _pendingLookup?.cancel();
    state.value = const FlightPreviewHidden();
    if (!isFlightNumberKind || FlightNumber.tryParse(input) == null) {
      return;
    }
    _pendingLookup = Timer(debounce, () => _lookUpRoute(input));
  }

  Future<void> _lookUpRoute(String input) async {
    final flightNumber = FlightNumber.tryParse(input);
    if (flightNumber == null) {
      return;
    }
    final result = await _routeLookup.lookup(
      _airlineDirectory.callsignCandidates(flightNumber),
    );
    if (_requestedInput != input) {
      return;
    }
    state.value = switch (result) {
      RouteFound(:final callsign, :final route) => FlightPreviewFound(
        callsign: callsign,
        route: route,
      ),
      RouteNotFound() ||
      RouteLookupFailure() => const FlightPreviewRouteUnknown(),
    };
  }
}
