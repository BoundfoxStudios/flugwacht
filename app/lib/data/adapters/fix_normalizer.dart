import '../../domain/fix.dart';
import '../../domain/source_id.dart';

Fix normalizeFix(
  Map<String, dynamic> aircraft, {
  required num serverNowMilliseconds,
  required SourceId sourceId,
}) {
  final hexAddress = aircraft['hex'];
  if (hexAddress is! String) {
    throw const FormatException('readsb aircraft entry has no hex address');
  }
  return Fix(
    hexAddress: hexAddress,
    callsign: _trimmedOrNull(aircraft['flight']),
    registration: aircraft['r'] as String?,
    aircraftType: aircraft['t'] as String?,
    position: _normalizePosition(aircraft, serverNowMilliseconds),
    sourceId: sourceId,
  );
}

FixPosition? _normalizePosition(
  Map<String, dynamic> aircraft,
  num serverNowMilliseconds,
) {
  final latitude = aircraft['lat'];
  final longitude = aircraft['lon'];
  final seenPositionSeconds = aircraft['seen_pos'];
  if (latitude is! num || longitude is! num || seenPositionSeconds is! num) {
    return _normalizeLastPosition(aircraft, serverNowMilliseconds);
  }
  final barometricAltitude = aircraft['alt_baro'];
  return FixPosition(
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      (serverNowMilliseconds - seenPositionSeconds * 1000).round(),
      isUtc: true,
    ),
    barometricAltitudeFeet: _doubleOrNull(barometricAltitude),
    onGround: switch (barometricAltitude) {
      'ground' => true,
      num() => false,
      _ => null,
    },
    geometricAltitudeFeet: _doubleOrNull(aircraft['alt_geom']),
    trackDegrees: _doubleOrNull(aircraft['track']),
    trueHeadingDegrees: _doubleOrNull(aircraft['true_heading']),
    groundSpeedKnots: _doubleOrNull(aircraft['gs']),
    indicatedAirspeedKnots: _doubleOrNull(aircraft['ias']),
    mach: _doubleOrNull(aircraft['mach']),
    verticalRateFeetPerMinute: _doubleOrNull(aircraft['baro_rate']),
  );
}

/// readsb drops the top-level position once it ages out (~60 s) and keeps it
/// in `lastPosition`; only the coordinates travel along, the remaining
/// top-level fields are staler than the position and stay out.
FixPosition? _normalizeLastPosition(
  Map<String, dynamic> aircraft,
  num serverNowMilliseconds,
) {
  final lastPosition = aircraft['lastPosition'];
  if (lastPosition is! Map<String, dynamic>) {
    return null;
  }
  final latitude = lastPosition['lat'];
  final longitude = lastPosition['lon'];
  final seenPositionSeconds = lastPosition['seen_pos'];
  if (latitude is! num || longitude is! num || seenPositionSeconds is! num) {
    return null;
  }
  return FixPosition(
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      (serverNowMilliseconds - seenPositionSeconds * 1000).round(),
      isUtc: true,
    ),
  );
}

double? _doubleOrNull(Object? value) => value is num ? value.toDouble() : null;

String? _trimmedOrNull(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
