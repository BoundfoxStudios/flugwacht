import 'package:flutter/material.dart';

import '../../l10n/app_localizations.g.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text(
        AppLocalizations.of(context).tabMore,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    ),
  );
}
