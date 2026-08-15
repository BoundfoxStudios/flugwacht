import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'data/airline_directory.dart';
import 'data/database.dart';
import 'data/flight_repository.dart';
import 'data/route_lookup.dart';
import 'l10n/app_localizations.g.dart';
import 'ui/app_router.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(
    FlugwachtApp(
      router: createAppRouter(
        flightRepository: FlightRepository(AppDatabase()),
        airlineDirectory: await AirlineDirectory.loadFromAssets(),
        routeLookup: RouteLookup(client: http.Client()),
      ),
    ),
  );
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
