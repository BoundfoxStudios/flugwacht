import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flugwacht/data/lookup_result.dart';
import 'package:flugwacht/data/readsb_source_adapter.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const emptyEnvelope = '{"ac": [], "now": 1786712583001}';

  ReadsbSourceAdapter adapterReturning(
    String body, {
    SourceId sourceId = SourceId.adsblol,
    int statusCode = 200,
    void Function(http.Request request)? onRequest,
  }) => ReadsbSourceAdapter(
    sourceId: sourceId,
    client: MockClient((request) async {
      onRequest?.call(request);
      return http.Response(body, statusCode);
    }),
  );

  Future<String> requestedUrl(
    SourceId sourceId,
    Future<LookupResult> Function(ReadsbSourceAdapter adapter) lookup,
  ) async {
    late String url;
    final adapter = adapterReturning(
      emptyEnvelope,
      sourceId: sourceId,
      onRequest: (request) => url = request.url.toString(),
    );
    await lookup(adapter);
    return url;
  }

  group('request URLs', () {
    test('looks up by hex on the hex path', () async {
      expect(
        await requestedUrl(
          SourceId.adsblol,
          (adapter) => adapter.lookupByHexAddress('3c64c6'),
        ),
        'https://api.adsb.lol/v2/hex/3c64c6',
      );
    });

    test('looks up by callsign on the callsign path', () async {
      expect(
        await requestedUrl(
          SourceId.adsbfi,
          (adapter) => adapter.lookupByCallsign('DLH433'),
        ),
        'https://opendata.adsb.fi/api/v2/callsign/DLH433',
      );
    });

    test(
      'looks up by registration on the adsb.lol registration path',
      () async {
        expect(
          await requestedUrl(
            SourceId.adsblol,
            (adapter) => adapter.lookupByRegistration('D-AIFF'),
          ),
          'https://api.adsb.lol/v2/registration/D-AIFF',
        );
      },
    );

    test('looks up by registration on the adsb.fi registration path', () async {
      expect(
        await requestedUrl(
          SourceId.adsbfi,
          (adapter) => adapter.lookupByRegistration('D-AIFF'),
        ),
        'https://opendata.adsb.fi/api/v2/registration/D-AIFF',
      );
    });

    test('looks up by registration on the airplanes.live reg path', () async {
      expect(
        await requestedUrl(
          SourceId.airplanes,
          (adapter) => adapter.lookupByRegistration('D-AIFF'),
        ),
        'https://api.airplanes.live/v2/reg/D-AIFF',
      );
    });

    test('encodes a lookup value into a single path segment', () async {
      expect(
        await requestedUrl(
          SourceId.adsblol,
          (adapter) => adapter.lookupByCallsign('A/B C'),
        ),
        'https://api.adsb.lol/v2/callsign/A%2FB%20C',
      );
    });

    test('sends GET requests', () async {
      late String method;
      final adapter = adapterReturning(
        emptyEnvelope,
        onRequest: (request) => method = request.method,
      );

      await adapter.lookupByHexAddress('3c64c6');

      expect(method, 'GET');
    });
  });

  group('success', () {
    test(
      'normalizes populated ac entries into fixes tagged with the source',
      () async {
        final adapter = adapterReturning(
          json.encode({
            'ac': [
              {
                'hex': '3c64c6',
                'flight': 'DLH433  ',
                'r': 'D-AIFF',
                't': 'A343',
                'lat': 49.875687,
                'lon': 7.888834,
                'seen_pos': 0.386,
                'alt_baro': 8575,
                'track': 43.81,
                'gs': 271.6,
              },
              {'hex': '406c39'},
            ],
            'now': 1786712583001,
          }),
          sourceId: SourceId.adsbfi,
        );

        final result = await adapter.lookupByCallsign('DLH433');

        final success = result as LookupSuccess;
        expect(success.fixes, hasLength(2));
        final airborne = success.fixes.first;
        expect(airborne.hexAddress, '3c64c6');
        expect(airborne.callsign, 'DLH433');
        expect(airborne.registration, 'D-AIFF');
        expect(airborne.sourceId, SourceId.adsbfi);
        expect(airborne.position!.latitude, 49.875687);
        expect(airborne.position!.groundSpeedKnots, 271.6);
        expect(
          airborne.position!.timestamp,
          DateTime.fromMillisecondsSinceEpoch(1786712583001 - 386, isUtc: true),
        );
        expect(success.fixes.last.hexAddress, '406c39');
        expect(success.fixes.last.position, isNull);
      },
    );

    test('treats an empty ac array as a successful empty result', () async {
      final result = await adapterReturning(
        emptyEnvelope,
      ).lookupByHexAddress('3c64c6');

      expect(result, isA<LookupSuccess>());
      expect((result as LookupSuccess).fixes, isEmpty);
    });

    test('treats any 2xx status as a success', () async {
      final result = await adapterReturning(
        emptyEnvelope,
        statusCode: 299,
      ).lookupByHexAddress('3c64c6');

      expect(result, isA<LookupSuccess>());
    });

    test('decodes the body as UTF-8 regardless of the content type', () async {
      final adapter = ReadsbSourceAdapter(
        sourceId: SourceId.adsblol,
        client: MockClient(
          (request) async => http.Response.bytes(
            utf8.encode(
              '{"ac": [{"hex": "3c64c6", "r": "D-AÜFF"}], "now": 1786712583001}',
            ),
            200,
          ),
        ),
      );

      final result = await adapter.lookupByHexAddress('3c64c6');

      expect((result as LookupSuccess).fixes.single.registration, 'D-AÜFF');
    });
  });

  group('status failures', () {
    for (final statusCode in [199, 301, 404, 500]) {
      test(
        'maps a $statusCode response to a status failure carrying the code',
        () async {
          final result = await adapterReturning(
            'error',
            statusCode: statusCode,
          ).lookupByHexAddress('3c64c6');

          expect(result, isA<LookupStatusFailure>());
          expect((result as LookupStatusFailure).statusCode, statusCode);
        },
      );
    }
  });

  group('network failures', () {
    ReadsbSourceAdapter adapterWith(MockClient client) =>
        ReadsbSourceAdapter(sourceId: SourceId.adsblol, client: client);

    test('maps a client exception to a network failure', () async {
      final adapter = adapterWith(
        MockClient(
          (request) async => throw http.ClientException('connection refused'),
        ),
      );

      expect(
        await adapter.lookupByHexAddress('3c64c6'),
        isA<LookupNetworkFailure>(),
      );
    });

    test('maps any other throw while sending to a network failure', () async {
      final adapter = adapterWith(
        MockClient((request) async => throw StateError('handshake failed')),
      );

      expect(
        await adapter.lookupByHexAddress('3c64c6'),
        isA<LookupNetworkFailure>(),
      );
    });

    test('maps a request exceeding the timeout to a network failure', () async {
      final adapter = ReadsbSourceAdapter(
        sourceId: SourceId.adsblol,
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return http.Response(emptyEnvelope, 200);
        }),
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        await adapter.lookupByHexAddress('3c64c6'),
        isA<LookupNetworkFailure>(),
      );
    });
  });

  group('malformed payloads', () {
    const bodiesByCase = <String, String>{
      'a non-JSON body': 'not json',
      'top-level JSON that is not a map': '[]',
      'an envelope without ac': '{"now": 1786712583001}',
      'an envelope with a null ac': '{"ac": null, "now": 1786712583001}',
      'a non-map entry inside ac': '{"ac": [42], "now": 1786712583001}',
      'an entry without hex':
          '{"ac": [{"flight": "DLH433  "}], "now": 1786712583001}',
      'an entry with a wrong-typed field':
          '{"ac": [{"hex": "3c64c6", "r": 5}], "now": 1786712583001}',
      'a populated ac without now': '{"ac": [{"hex": "3c64c6"}]}',
      'an empty ac without now': '{"ac": []}',
      'a non-numeric now': '{"ac": [], "now": "1786712583001"}',
    };

    for (final malformed in bodiesByCase.entries) {
      test('maps ${malformed.key} to a malformed payload', () async {
        final result = await adapterReturning(
          malformed.value,
        ).lookupByHexAddress('3c64c6');

        expect(result, isA<LookupMalformedPayload>());
      });
    }
  });

  group('rate limiting', () {
    test('spaces same-source lookups one second apart', () {
      fakeAsync((async) {
        var requestCount = 0;
        adapterReturning(emptyEnvelope, onRequest: (_) => requestCount++)
          ..lookupByHexAddress('3c64c6')
          ..lookupByHexAddress('3c64c6')
          ..lookupByHexAddress('3c64c6');

        async.flushMicrotasks();
        expect(requestCount, 1);

        async.elapse(const Duration(milliseconds: 999));
        expect(requestCount, 1);
        async.elapse(const Duration(milliseconds: 1));
        expect(requestCount, 2);

        async.elapse(const Duration(milliseconds: 999));
        expect(requestCount, 2);
        async.elapse(const Duration(milliseconds: 1));
        expect(requestCount, 3);
      });
    });

    test('does not delay lookups across different sources', () {
      fakeAsync((async) {
        var requestCount = 0;
        adapterReturning(
          emptyEnvelope,
          onRequest: (_) => requestCount++,
        ).lookupByHexAddress('3c64c6');
        adapterReturning(
          emptyEnvelope,
          sourceId: SourceId.adsbfi,
          onRequest: (_) => requestCount++,
        ).lookupByHexAddress('3c64c6');
        async.flushMicrotasks();

        expect(requestCount, 2);
      });
    });

    test('does not count queue wait toward the timeout', () {
      fakeAsync((async) {
        var requestCount = 0;
        final adapter = ReadsbSourceAdapter(
          sourceId: SourceId.adsblol,
          client: MockClient((request) async {
            requestCount++;
            if (requestCount == 1) {
              await Future<void>.delayed(const Duration(seconds: 2));
            }
            return http.Response(emptyEnvelope, 200);
          }),
          timeout: const Duration(milliseconds: 500),
        );
        LookupResult? first;
        LookupResult? second;
        adapter
          ..lookupByHexAddress('3c64c6').then((result) => first = result)
          ..lookupByHexAddress('3c64c6').then((result) => second = result);

        async.elapse(const Duration(milliseconds: 500));
        expect(first, isA<LookupNetworkFailure>());
        expect(second, isNull);

        async.elapse(const Duration(milliseconds: 500));
        expect(second, isA<LookupSuccess>());
      });
    });
  });
}
