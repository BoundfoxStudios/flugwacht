import 'source_id.dart';

class TrailPoint {
  const TrailPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.sourceId,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final SourceId sourceId;
}
