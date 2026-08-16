import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../data/vector_tile_source.dart';
import 'app_tokens.dart';

/// The reduced style of the design board, built from the app tokens instead of
/// a bundled style file: land as the ground, water a shade off it, country
/// borders barely there — no labels, no roads, no buildings.
Theme reducedMapTheme(Brightness brightness) => switch (brightness) {
  Brightness.light => _lightTheme,
  Brightness.dark => _darkTheme,
};

final _lightTheme = ThemeReader().read(
  _styleJson(
    land: AppColors.neutral100,
    water: AppColors.white,
    border: AppColors.neutral200,
  ),
);

final _darkTheme = ThemeReader().read(
  _styleJson(
    land: AppColors.neutral800,
    water: AppColors.neutral900,
    border: AppColors.neutral700,
  ),
);

Map<String, dynamic> _styleJson({
  required Color land,
  required Color water,
  required Color border,
}) => {
  'version': 8,
  'name': 'Flugwacht reduced',
  'sources': {
    VectorTileSource.styleSourceName: {'type': 'vector'},
  },
  'layers': [
    {
      'id': 'land',
      'type': 'background',
      'paint': {'background-color': _hex(land)},
    },
    {
      'id': 'water',
      'type': 'fill',
      'source': VectorTileSource.styleSourceName,
      'source-layer': 'water',
      'paint': {'fill-color': _hex(water)},
    },
    {
      'id': 'border',
      'type': 'line',
      'source': VectorTileSource.styleSourceName,
      'source-layer': 'boundary',
      'filter': ['<=', 'admin_level', 2],
      'paint': {'line-color': _hex(border), 'line-width': 1},
    },
  ],
};

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';
