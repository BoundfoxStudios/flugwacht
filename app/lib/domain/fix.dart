import 'source_id.dart';

class Fix {
  const Fix({
    required this.hexAddress,
    required this.sourceId,
    this.callsign,
    this.registration,
    this.aircraftType,
    this.position,
  });

  final String hexAddress;
  final String? callsign;
  final String? registration;
  final String? aircraftType;
  final FixPosition? position;
  final SourceId sourceId;
}

class FixPosition {
  const FixPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.barometricAltitudeFeet,
    this.onGround,
    this.geometricAltitudeFeet,
    this.trackDegrees,
    this.trueHeadingDegrees,
    this.groundSpeedKnots,
    this.indicatedAirspeedKnots,
    this.mach,
    this.verticalRateFeetPerMinute,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? barometricAltitudeFeet;
  final bool? onGround;
  final double? geometricAltitudeFeet;
  final double? trackDegrees;
  final double? trueHeadingDegrees;
  final double? groundSpeedKnots;
  final double? indicatedAirspeedKnots;
  final double? mach;
  final double? verticalRateFeetPerMinute;
}
