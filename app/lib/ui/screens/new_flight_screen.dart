import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class NewFlightScreen extends StatelessWidget {
  const NewFlightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.newFlightTitle)),
      body: Center(child: Text(localizations.newFlightTitle)),
    );
  }
}
