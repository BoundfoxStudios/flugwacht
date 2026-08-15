import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/ui/screens/new_flight_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late NewFlightForm form;

  setUp(() => form = NewFlightForm(today: DateTime(2026, 8, 12)));
  tearDown(() => form.dispose());

  test('starts on the flight number kind with an invalid empty input', () {
    expect(form.lookupKind.value, FlightLookupKind.flightNumber);
    expect(form.isValid.value, isFalse);
  });

  test('accepts a parseable flight number', () {
    form.inputFor(FlightLookupKind.flightNumber).value = 'LH 400';

    expect(form.isValid.value, isTrue);
  });

  test('validates the input of the selected kind only', () {
    form.inputFor(FlightLookupKind.flightNumber).value = 'LH 400';
    form.lookupKind.value = FlightLookupKind.hexAddress;

    expect(form.isValid.value, isFalse);

    form.inputFor(FlightLookupKind.hexAddress).value = '3C6444';

    expect(form.isValid.value, isTrue);
  });

  test('accepts a registration and rejects a malformed one', () {
    form.lookupKind.value = FlightLookupKind.registration;
    form.inputFor(FlightLookupKind.registration).value = 'D-AIMA';

    expect(form.isValid.value, isTrue);

    form.inputFor(FlightLookupKind.registration).value = 'D';

    expect(form.isValid.value, isFalse);
  });

  test('rejects a hex address that is not six hex digits', () {
    form.lookupKind.value = FlightLookupKind.hexAddress;
    form.inputFor(FlightLookupKind.hexAddress).value = '3C64';

    expect(form.isValid.value, isFalse);

    form.inputFor(FlightLookupKind.hexAddress).value = 'XYZXYZ';

    expect(form.isValid.value, isFalse);
  });

  test('keeps the input of every kind while switching', () {
    form.inputFor(FlightLookupKind.flightNumber).value = 'LH 400';
    form.lookupKind.value = FlightLookupKind.registration;
    form.inputFor(FlightLookupKind.registration).value = 'D-AIMA';
    form.lookupKind.value = FlightLookupKind.flightNumber;

    expect(form.inputFor(FlightLookupKind.flightNumber).value, 'LH 400');
    expect(form.inputFor(FlightLookupKind.registration).value, 'D-AIMA');
  });

  test('hints at low cost carriers whose callsign differs', () {
    void enterFlightNumber(String value) =>
        form.inputFor(FlightLookupKind.flightNumber).value = value;

    enterFlightNumber('FR 1234');
    expect(form.showsLowCostCarrierHint.value, isTrue);
    enterFlightNumber('U2 8511');
    expect(form.showsLowCostCarrierHint.value, isTrue);
    enterFlightNumber('W6 2464');
    expect(form.showsLowCostCarrierHint.value, isTrue);
    enterFlightNumber('LH 400');
    expect(form.showsLowCostCarrierHint.value, isFalse);
  });

  test('hides the low cost carrier hint outside the flight number kind', () {
    form.inputFor(FlightLookupKind.flightNumber).value = 'FR 1234';
    form.lookupKind.value = FlightLookupKind.registration;

    expect(form.showsLowCostCarrierHint.value, isFalse);
  });

  test('starts on today and offers yesterday until one year ahead', () {
    expect(form.departureDate.value, DateTime(2026, 8, 12));
    expect(form.earliestDepartureDate, DateTime(2026, 8, 11));
    expect(form.latestDepartureDate, DateTime(2027, 8, 12));
  });
}
