import 'package:flugwacht/domain/calendar_date.dart';
import 'package:flugwacht/domain/day_time.dart';
import 'package:flugwacht/domain/departure_time.dart';
import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter_test/flutter_test.dart';

const _taipeiToJakarta = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'RCTP',
    iataCode: 'TPE',
    name: 'Taiwan Taoyuan',
    latitude: 25.0777,
    longitude: 121.2328,
  ),
  destination: RouteAirport(
    icaoCode: 'WIII',
    iataCode: 'CGK',
    name: 'Jakarta Soekarno-Hatta',
    latitude: -6.1256,
    longitude: 106.6558,
  ),
);

Flight _flight({
  DayTime? departureTime = const DayTime(9, 0),
  DepartureTimeInterpretation departureTimeInterpretation =
      DepartureTimeInterpretation.originLocal,
  FlightRoute? route = _taipeiToJakarta,
}) => Flight(
  id: 1,
  lookupKind: FlightLookupKind.flightNumber,
  lookupValue: 'BR237',
  departureDate: const CalendarDate(2026, 3, 17),
  departureTime: departureTime,
  departureTimeInterpretation: departureTimeInterpretation,
  route: route,
);

void main() {
  test('reads an origin-local departure in the origin zone', () {
    expect(departureInstantOf(_flight()), DateTime.utc(2026, 3, 17, 1, 0));
  });

  test('reads a device departure on the device clock', () {
    expect(
      departureInstantOf(
        _flight(
          departureTimeInterpretation: DepartureTimeInterpretation.device,
        ),
      ),
      DateTime(2026, 3, 17, 9, 0),
    );
  });

  test('falls back to the device clock without a route', () {
    expect(
      departureInstantOf(_flight(route: null)),
      DateTime(2026, 3, 17, 9, 0),
    );
  });

  test('names no instant without a departure time', () {
    expect(departureInstantOf(_flight(departureTime: null)), isNull);
  });
}
