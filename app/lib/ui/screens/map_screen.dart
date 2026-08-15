import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text(
        AppLocalizations.of(context).tabMap,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    ),
  );
}
