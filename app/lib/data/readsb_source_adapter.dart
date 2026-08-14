import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/fix.dart';
import '../domain/source_id.dart';
import 'fix_normalizer.dart';
import 'lookup_result.dart';
import 'rate_limiter.dart';
import 'source_adapter.dart';

class ReadsbSourceAdapter implements SourceAdapter {
  ReadsbSourceAdapter({
    required this._sourceId,
    required this._client,
    this._timeout = const Duration(seconds: 10),
  });

  final SourceId _sourceId;
  final http.Client _client;
  final Duration _timeout;
  final RateLimiter _rateLimiter = RateLimiter(
    minimumInterval: const Duration(seconds: 1),
  );

  @override
  Future<LookupResult> lookupByHexAddress(String hexAddress) =>
      _lookup('hex', hexAddress);

  @override
  Future<LookupResult> lookupByCallsign(String callsign) =>
      _lookup('callsign', callsign);

  @override
  Future<LookupResult> lookupByRegistration(String registration) =>
      _lookup(_registrationPath, registration);

  Future<LookupResult> _lookup(String path, String value) =>
      _rateLimiter.schedule(() => _fetch(path, value));

  Future<LookupResult> _fetch(String path, String value) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/$path/${Uri.encodeComponent(value)}'))
          .timeout(_timeout);
    } on Object catch (_) {
      return const LookupNetworkFailure();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return LookupStatusFailure(response.statusCode);
    }
    try {
      return LookupSuccess(_parseFixes(response.bodyBytes));
    } on Object catch (_) {
      return const LookupMalformedPayload();
    }
  }

  List<Fix> _parseFixes(List<int> bodyBytes) {
    final envelope =
        json.decode(utf8.decode(bodyBytes)) as Map<String, dynamic>;
    final serverNowMilliseconds = envelope['now'] as num;
    final aircraftEntries = (envelope['ac'] as List)
        .cast<Map<String, dynamic>>();
    return aircraftEntries
        .map(
          (entry) => normalizeFix(
            entry,
            serverNowMilliseconds: serverNowMilliseconds,
            sourceId: _sourceId,
          ),
        )
        .toList();
  }

  String get _baseUrl => switch (_sourceId) {
    SourceId.adsblol => 'https://api.adsb.lol/v2',
    SourceId.adsbfi => 'https://opendata.adsb.fi/api/v2',
    SourceId.airplanes => 'https://api.airplanes.live/v2',
  };

  String get _registrationPath => switch (_sourceId) {
    SourceId.airplanes => 'reg',
    SourceId.adsblol || SourceId.adsbfi => 'registration',
  };
}
