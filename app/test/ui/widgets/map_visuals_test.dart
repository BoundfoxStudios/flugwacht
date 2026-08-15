import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/ui/widgets/map_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _route = FlightRoute(
  origin: RouteAirport(
    icaoCode: 'EDDF',
    iataCode: 'FRA',
    name: 'Frankfurt am Main',
    latitude: 50.026402,
    longitude: 8.543130,
  ),
  destination: RouteAirport(
    icaoCode: 'KJFK',
    iataCode: 'JFK',
    name: 'New York JFK',
    latitude: 40.639447,
    longitude: -73.779317,
  ),
);

final _position = FixPosition(
  latitude: 48.5,
  longitude: -20,
  timestamp: DateTime.utc(2026, 8, 12, 12),
  trackDegrees: 271.4,
);

void main() {
  test('keeps route, trail and position in view', () {
    final trail = [
      TrailPoint(
        timestamp: DateTime.utc(2026, 8, 12, 11),
        latitude: 49,
        longitude: 2,
        sourceId: SourceId.adsblol,
      ),
    ];

    expect(
      flightFocusPoints(position: _position, route: _route, trail: trail),
      [
        const LatLng(50.026402, 8.543130),
        const LatLng(40.639447, -73.779317),
        const LatLng(49, 2),
        const LatLng(48.5, -20),
      ],
    );
  });

  test('falls back to the position alone without a route', () {
    expect(
      flightFocusPoints(position: _position, route: null, trail: const []),
      [const LatLng(48.5, -20)],
    );
  });

  test('has no camera fit for a single point', () {
    expect(
      cameraFitFor(const [LatLng(50, 10)], padding: EdgeInsets.zero),
      isNull,
    );
  });

  test('has no camera fit for points on one spot of the globe', () {
    expect(
      cameraFitFor(const [
        LatLng(50, 10),
        LatLng(50.001, 10.001),
      ], padding: EdgeInsets.zero),
      isNull,
    );
  });

  test('fits the bounds of points that span a distance', () {
    final fit = cameraFitFor(const [
      LatLng(50, 10),
      LatLng(40, -73),
    ], padding: const EdgeInsets.all(40));

    expect(
      fit,
      isA<FitBounds>()
          .having((fit) => fit.bounds.north, 'north', 50)
          .having((fit) => fit.bounds.south, 'south', 40)
          .having((fit) => fit.bounds.east, 'east', 10)
          .having((fit) => fit.bounds.west, 'west', -73)
          .having((fit) => fit.padding, 'padding', const EdgeInsets.all(40)),
    );
  });
}
