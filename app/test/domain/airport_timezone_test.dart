import 'package:flugwacht/domain/airport_timezone.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RouteAirport airportAt(double latitude, double longitude) => RouteAirport(
    icaoCode: 'ZZZZ',
    name: 'Airport',
    latitude: latitude,
    longitude: longitude,
  );

  final kennedy = airportAt(40.6413, -73.7781);
  final frankfurt = airportAt(50.0379, 8.5622);
  final schiphol = airportAt(52.3105, 4.7683);
  final midAtlantic = airportAt(30, -40);

  final summerNoon = DateTime.utc(2026, 7, 1, 12);
  final winterNoon = DateTime.utc(2026, 1, 1, 12);

  setUpAll(initializeAirportTimezones);

  group('zone resolution', () {
    test('resolves the destination coordinates to their zone', () {
      expect(
        airportLocalTime(kennedy, summerNoon)?.location.name,
        'America/New_York',
      );
      expect(
        airportLocalTime(frankfurt, summerNoon)?.location.name,
        'Europe/Berlin',
      );
    });

    test('resolves a zone the reduced database leaves out', () {
      expect(
        airportLocalTime(schiphol, summerNoon)?.location.name,
        'Europe/Amsterdam',
      );
    });

    test('resolves a coordinate far off any airport', () {
      final localTime = airportLocalTime(midAtlantic, summerNoon);
      expect(localTime?.location.name, 'Atlantic/Azores');
      expect(localTime?.hour, 12);
    });
  });

  group('conversion', () {
    test('applies daylight saving time in summer', () {
      final localTime = airportLocalTime(kennedy, summerNoon)!;
      expect(localTime.hour, 8);
      expect(localTime.timeZoneOffset, const Duration(hours: -4));
    });

    test('applies standard time in winter', () {
      final localTime = airportLocalTime(kennedy, winterNoon)!;
      expect(localTime.hour, 7);
      expect(localTime.timeZoneOffset, const Duration(hours: -5));
    });

    test('keeps the instant it was given', () {
      expect(airportLocalTime(kennedy, summerNoon)!.toUtc(), summerNoon);
    });
  });
}
