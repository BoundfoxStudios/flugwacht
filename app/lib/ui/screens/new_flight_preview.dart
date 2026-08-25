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

/// The standing data named a rotation rather than one leg, so the flight has
/// no route until the user says which of the legs is theirs.
class FlightPreviewLegChoice extends FlightPreviewState {
  const FlightPreviewLegChoice({required this.callsign, required this.legs});

  final String callsign;
  final List<FlightRoute> legs;
}

class FlightPreviewRouteUnknown extends FlightPreviewState {
  const FlightPreviewRouteUnknown();
}

class FlightPreviewSearching extends FlightPreviewState {
  const FlightPreviewSearching();
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

  /// Counts the requests the form asked for, so an answer that a later one has
  /// outdated is dropped even when both asked for the same flight number.
  var _requestCount = 0;
  var _isDisposed = false;

  void dispose() {
    _isDisposed = true;
    _pendingLookup?.cancel();
    _stopWatchingForm();
    state.dispose();
  }

  void _onFormChanged() {
    final input = _form.inputFor(FlightLookupKind.flightNumber).value;
    final isFlightNumberKind =
        _form.lookupKind.value == FlightLookupKind.flightNumber;
    _requestCount++;
    _pendingLookup?.cancel();
    if (!isFlightNumberKind || FlightNumber.tryParse(input) == null) {
      state.value = const FlightPreviewHidden();
      return;
    }
    state.value = const FlightPreviewSearching();
    final request = _requestCount;
    _pendingLookup = Timer(debounce, () => _lookUpRoute(input, request));
  }

  Future<void> _lookUpRoute(String input, int request) async {
    final flightNumber = FlightNumber.tryParse(input);
    if (flightNumber == null) {
      return;
    }
    final result = await _routeLookup.lookup(
      _airlineDirectory.callsignCandidates(flightNumber),
    );
    if (_isDisposed || request != _requestCount) {
      return;
    }
    state.value = switch (result) {
      RouteFound(:final callsign, :final route) => FlightPreviewFound(
        callsign: callsign,
        route: route,
      ),
      RouteLegsFound(:final callsign, :final legs) => FlightPreviewLegChoice(
        callsign: callsign,
        legs: legs,
      ),
      RouteNotFound() ||
      RouteLookupFailure() => const FlightPreviewRouteUnknown(),
    };
  }

  /// Takes the leg the user picked out of a rotation, which is the only source
  /// that knows it.
  void chooseLeg(FlightRoute leg) {
    final choice = state.value;
    if (choice is! FlightPreviewLegChoice) {
      return;
    }
    state.value = FlightPreviewFound(callsign: choice.callsign, route: leg);
  }
}
