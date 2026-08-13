import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(AppLocalizations.of(context).tabMap)));
}
