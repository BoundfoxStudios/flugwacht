import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'ui/app_router.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(FlugwachtApp(router: createAppRouter()));
}

class FlugwachtApp extends StatelessWidget {
  const FlugwachtApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    routerConfig: router,
  );
}
