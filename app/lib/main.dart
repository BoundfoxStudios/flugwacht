import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'ui/app_router.dart';
import 'ui/theme/app_theme.dart';

void main() {
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(FlugwachtApp(router: createAppRouter()));
}

Stream<LicenseEntry> _fontLicenses() async* {
  yield LicenseEntryWithLineBreaks(const [
    'Bebas Neue',
  ], await rootBundle.loadString('assets/fonts/OFL-BebasNeue.txt'));
  yield LicenseEntryWithLineBreaks(const [
    'Barlow',
  ], await rootBundle.loadString('assets/fonts/OFL-Barlow.txt'));
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
