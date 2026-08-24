/// The identifier a card runs under. Unique per start: a card the system
/// already dismissed must not have its identifier reused by the next one.
String liveActivityIdOf(int flightId, DateTime startedAt) =>
    'flight-$flightId-${startedAt.millisecondsSinceEpoch}';

/// The flight a card belongs to, for a service that has to reach the flight's
/// notification slot from an identifier an earlier app run handed out.
int? flightIdFromLiveActivityId(String activityId) {
  final parts = activityId.split('-');
  return parts.length == 3 && parts.first == 'flight'
      ? int.tryParse(parts[1])
      : null;
}
