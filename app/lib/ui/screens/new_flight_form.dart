import 'package:signals/signals.dart';

import '../../data/lookup/airline_directory.dart';
import '../../domain/day_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_number.dart';
import '../../domain/lookup_input.dart';

class NewFlightForm {
  NewFlightForm({required DateTime today, bool armsLiveActivity = false})
    : _today = DateTime(today.year, today.month, today.day),
      liveActivityArmed = signal(armsLiveActivity) {
    departureDate = signal(_today);
  }

  final DateTime _today;

  final lookupKind = signal(FlightLookupKind.flightNumber);
  final note = signal('');
  final departureTime = signal<DayTime?>(null);
  final departureTimeIsOriginLocal = signal(true);
  final Signal<bool> liveActivityArmed;
  late final Signal<DateTime> departureDate;

  final _inputs = {
    for (final kind in FlightLookupKind.values) kind: signal(''),
  };

  late final isValid = computed(() {
    final input = inputFor(lookupKind.value).value;
    return switch (lookupKind.value) {
      FlightLookupKind.flightNumber => FlightNumber.tryParse(input) != null,
      FlightLookupKind.registration => normalizedRegistration(input) != null,
      FlightLookupKind.hexAddress => normalizedHexAddress(input) != null,
    };
  });

  late final showsLowCostCarrierHint = computed(() {
    if (lookupKind.value != FlightLookupKind.flightNumber) {
      return false;
    }
    final flightNumber = FlightNumber.tryParse(
      inputFor(FlightLookupKind.flightNumber).value,
    );
    return flightNumber != null &&
        AirlineDirectory.isLowCostCarrier(flightNumber.airlineCode);
  });

  // A night flight can be added while it is already airborne, so yesterday
  // stays selectable.
  DateTime get earliestDepartureDate =>
      _today.subtract(const Duration(days: 1));

  DateTime get latestDepartureDate =>
      DateTime(_today.year + 1, _today.month, _today.day);

  Signal<String> inputFor(FlightLookupKind kind) => _inputs[kind]!;

  void dispose() {
    for (final input in _inputs.values) {
      input.dispose();
    }
    lookupKind.dispose();
    note.dispose();
    departureDate.dispose();
    departureTime.dispose();
    departureTimeIsOriginLocal.dispose();
    liveActivityArmed.dispose();
    isValid.dispose();
    showsLowCostCarrierHint.dispose();
  }
}
