import 'dart:convert';
import 'dart:io';

import 'package:flugwacht/data/adapters/fix_normalizer.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final envelope =
      json.decode(
            File(
              'test/data/adapters/fixtures/readsb_response.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final aircraftEntries = (envelope['ac'] as List).cast<Map<String, dynamic>>();
  final serverNowMilliseconds = envelope['now'] as num;

  Fix normalizeByHex(
    String hexAddress, {
    SourceId sourceId = SourceId.adsblol,
  }) {
    final entry = aircraftEntries.singleWhere(
      (candidate) => candidate['hex'] == hexAddress,
    );
    return normalizeFix(
      entry,
      serverNowMilliseconds: serverNowMilliseconds,
      sourceId: sourceId,
    );
  }

  group('identity', () {
    test('trims the space-padded callsign and keeps registration and type', () {
      final fix = normalizeByHex('3c64c6');
      expect(fix.hexAddress, '3c64c6');
      expect(fix.callsign, 'DLH433');
      expect(fix.registration, 'D-AIFF');
      expect(fix.aircraftType, 'A343');
    });

    test(
      'normalizes an entry without flight, registration, and type with null identity fields',
      () {
        final fix = normalizeByHex('406c39');
        expect(fix.callsign, isNull);
        expect(fix.registration, isNull);
        expect(fix.aircraftType, isNull);
        expect(fix.position, isNotNull);
      },
    );

    test('normalizes an all-space callsign to null', () {
      final fix = normalizeFix(
        {'hex': 'abc123', 'flight': '        '},
        serverNowMilliseconds: serverNowMilliseconds,
        sourceId: SourceId.adsblol,
      );
      expect(fix.callsign, isNull);
    });

    test('throws on an entry without a hex address', () {
      expect(
        () => normalizeFix(
          {'flight': 'DLH433  '},
          serverNowMilliseconds: serverNowMilliseconds,
          sourceId: SourceId.adsblol,
        ),
        throwsFormatException,
      );
    });
  });

  group('position', () {
    test(
      'normalizes a full airborne entry with track as the direction field',
      () {
        final position = normalizeByHex('3c64c6').position!;
        expect(position.latitude, 49.875687);
        expect(position.longitude, 7.888834);
        expect(position.onGround, isFalse);
        expect(position.barometricAltitudeFeet, 8575.0);
        expect(position.geometricAltitudeFeet, 9300.0);
        expect(position.trackDegrees, 43.81);
        expect(position.trueHeadingDegrees, 43.62);
        expect(position.groundSpeedKnots, 271.6);
        expect(position.indicatedAirspeedKnots, 231.0);
        expect(position.mach, 0.408);
        expect(position.verticalRateFeetPerMinute, -896.0);
      },
    );

    test(
      'turns alt_baro "ground" into the on-ground flag with a null barometric altitude',
      () {
        final position = normalizeByHex('3c64c5').position!;
        expect(position.onGround, isTrue);
        expect(position.barometricAltitudeFeet, isNull);
        expect(position.groundSpeedKnots, 6.2);
        expect(position.trueHeadingDegrees, 160.31);
        expect(position.trackDegrees, isNull);
      },
    );

    test(
      'derives an absolute UTC timestamp from seen_pos and the server now',
      () {
        final timestamp = normalizeByHex('3c64c6').position!.timestamp;
        expect(
          timestamp,
          DateTime.fromMillisecondsSinceEpoch(1786712583001 - 386, isUtc: true),
        );
        expect(timestamp.isUtc, isTrue);
      },
    );

    test(
      'normalizes an entry without lat and lon to a fix with a null position and intact identity',
      () {
        final fix = normalizeByHex('4b1617');
        expect(fix.position, isNull);
        expect(fix.hexAddress, '4b1617');
        expect(fix.callsign, 'SWR458');
      },
    );

    test(
      'normalizes an entry with lat and lon but no velocity data with null velocity fields',
      () {
        final position = normalizeByHex('3d2461').position!;
        expect(position.latitude, 50.101512);
        expect(position.longitude, 8.701244);
        expect(position.barometricAltitudeFeet, 2800.0);
        expect(position.trackDegrees, isNull);
        expect(position.trueHeadingDegrees, isNull);
        expect(position.groundSpeedKnots, isNull);
        expect(position.indicatedAirspeedKnots, isNull);
        expect(position.mach, isNull);
        expect(position.verticalRateFeetPerMinute, isNull);
      },
    );
  });

  group('origin', () {
    test('carries the source the fix came from', () {
      for (final sourceId in SourceId.values) {
        expect(normalizeByHex('3c64c6', sourceId: sourceId).sourceId, sourceId);
      }
    });
  });
}
