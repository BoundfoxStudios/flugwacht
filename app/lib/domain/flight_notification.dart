/// The moments of a flight the app can notify about.
enum FlightNotification { departed, arrivingSoon, landed }

/// When each notification of a flight went out, so none of them ever goes out
/// twice.
class NotificationMarkers {
  const NotificationMarkers({
    this.departedAt,
    this.arrivingSoonAt,
    this.landedAt,
  });

  final DateTime? departedAt;
  final DateTime? arrivingSoonAt;
  final DateTime? landedAt;

  DateTime? deliveredAt(FlightNotification kind) => switch (kind) {
    FlightNotification.departed => departedAt,
    FlightNotification.arrivingSoon => arrivingSoonAt,
    FlightNotification.landed => landedAt,
  };

  bool isDelivered(FlightNotification kind) => deliveredAt(kind) != null;
}
