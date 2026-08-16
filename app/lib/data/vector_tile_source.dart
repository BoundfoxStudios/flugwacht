import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:signals/signals.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Where the reduced style takes its vector tiles from. OpenFreeMap uploads a
/// new planet run every week and serves it under a URL of its own, so the tile
/// template is read from the TileJSON instead of being a constant. Until it
/// arrives — and if it never does, offline — the map renders without tiles.
class VectorTileSource {
  VectorTileSource({required this.client});

  static const tileJsonUrl = 'https://tiles.openfreemap.org/planet';

  /// The source the reduced style names its layers after; OpenFreeMap serves
  /// the OpenMapTiles schema.
  static const styleSourceName = 'openmaptiles';

  final http.Client client;
  final _endpoint = signal<VectorTileEndpoint?>(null);

  ReadonlySignal<VectorTileEndpoint?> get endpoint => _endpoint;

  late final ReadonlySignal<TileProviders?> providers = computed(() {
    final endpoint = _endpoint.value;
    return endpoint == null
        ? null
        : TileProviders({
            styleSourceName: NetworkVectorTileProvider(
              urlTemplate: endpoint.urlTemplate,
              minimumZoom: endpoint.minimumZoom,
              maximumZoom: endpoint.maximumZoom,
            ),
          });
  });

  Future<void> load() async {
    _endpoint.value = await _readEndpoint();
  }

  void dispose() {
    providers.dispose();
    _endpoint.dispose();
  }

  Future<VectorTileEndpoint?> _readEndpoint() async {
    try {
      final response = await client.get(Uri.parse(tileJsonUrl));
      if (response.statusCode != 200) {
        return null;
      }
      final tileJson = jsonDecode(response.body) as Map<String, dynamic>;
      final tiles = tileJson['tiles'] as List<dynamic>?;
      final urlTemplate = tiles?.firstOrNull as String?;
      if (urlTemplate == null) {
        return null;
      }
      return VectorTileEndpoint(
        urlTemplate: urlTemplate,
        minimumZoom: tileJson['minzoom'] as int? ?? _defaultMinimumZoom,
        maximumZoom: tileJson['maxzoom'] as int? ?? _defaultMaximumZoom,
      );
    } on Exception {
      return null;
    }
  }

  static const _defaultMinimumZoom = 0;
  static const _defaultMaximumZoom = 14;
}

/// The tile template of one planet run and the zoom range it covers — beyond
/// its maximum zoom the map scales the last tiles up rather than asking for
/// more.
@immutable
class VectorTileEndpoint {
  const VectorTileEndpoint({
    required this.urlTemplate,
    required this.minimumZoom,
    required this.maximumZoom,
  });

  final String urlTemplate;
  final int minimumZoom;
  final int maximumZoom;
}
