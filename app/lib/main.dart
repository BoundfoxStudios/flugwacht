import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_icons.dart';

void main() {
  runApp(const FlugwachtApp());
}

class FlugwachtApp extends StatelessWidget {
  const FlugwachtApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flugwacht',
    theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    home: const IconGalleryPage(),
  );
}

class IconGalleryPage extends StatelessWidget {
  const IconGalleryPage({super.key});

  static const Map<String, FaIconData> _icons = {
    'map': AppIcons.map,
    'list': AppIcons.list,
    'sliders': AppIcons.sliders,
    'layer-group': AppIcons.layerGroup,
    'location-arrow': AppIcons.locationArrow,
    'calendar': AppIcons.calendar,
    'plus': AppIcons.plus,
    'chevron-right': AppIcons.chevronRight,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flugwacht')),
    body: ListView(
      children: [
        for (final entry in _icons.entries)
          ListTile(leading: FaIcon(entry.value), title: Text(entry.key)),
      ],
    ),
  );
}
