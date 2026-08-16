import 'dart:convert';

import 'package:flugwacht/data/vector_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const tileJson = {
    'tilejson': '3.0.0',
    'tiles': [
      'https://tiles.openfreemap.org/planet/20260802_080001_pt/{z}/{x}/{y}.pbf',
    ],
    'minzoom': 0,
    'maxzoom': 14,
  };

  VectorTileSource sourceReturning(String body, {int statusCode = 200}) {
    final source = VectorTileSource(
      client: MockClient((request) async => http.Response(body, statusCode)),
    );
    addTearDown(source.dispose);
    return source;
  }

  test(
    'takes the tile template of the current planet run from the TileJSON',
    () async {
      final source = sourceReturning(jsonEncode(tileJson));

      await source.load();

      expect(
        source.endpoint.value?.urlTemplate,
        'https://tiles.openfreemap.org/planet/20260802_080001_pt/{z}/{x}/{y}.pbf',
      );
    },
  );

  test(
    'takes the zoom range the tiles are served for from the TileJSON',
    () async {
      final source = sourceReturning(jsonEncode(tileJson));

      await source.load();

      expect(source.endpoint.value?.minimumZoom, 0);
      expect(source.endpoint.value?.maximumZoom, 14);
    },
  );

  test('stays without an endpoint when the TileJSON cannot be read', () async {
    final source = sourceReturning('nope', statusCode: 503);

    await source.load();

    expect(source.endpoint.value, isNull);
  });

  test('stays without an endpoint when the TileJSON names no tiles', () async {
    final source = sourceReturning(
      jsonEncode(const {'tilejson': '3.0.0', 'tiles': []}),
    );

    await source.load();

    expect(source.endpoint.value, isNull);
  });

  test(
    'serves the tiles under the source name the reduced style renders',
    () async {
      final source = sourceReturning(jsonEncode(tileJson));

      await source.load();

      expect(
        source.providers.value?.get(VectorTileSource.styleSourceName),
        isNotNull,
      );
    },
  );

  test('has no providers before the TileJSON was read', () {
    final source = sourceReturning(jsonEncode(tileJson));

    expect(source.providers.value, isNull);
  });
}
