class FlightRoute {
  const FlightRoute({required this.origin, required this.destination});

  final RouteAirport origin;
  final RouteAirport destination;
}

class RouteAirport {
  const RouteAirport({
    required this.icaoCode,
    this.iataCode,
    required this.name,
    this.location,
    required this.latitude,
    required this.longitude,
  });

  final String icaoCode;
  final String? iataCode;
  final String name;
  final String? location;
  final double latitude;
  final double longitude;
}
