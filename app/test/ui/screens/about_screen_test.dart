import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/about_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

Future<FakeUrlLauncher> pumpAboutScreen(
  WidgetTester tester, {
  String version = '1.4.2',
  Locale locale = const Locale('en'),
}) async {
  final launcher = createTestUrlLauncher();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: AboutScreen(packageInfo: testPackageInfo(version: version)),
    ),
  );
  await tester.pumpAndSettle();
  return launcher;
}

String textContaining(WidgetTester tester, String fragment) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .firstWhere((data) => data.contains(fragment));

void main() {
  testWidgets('names the app and the installed version', (tester) async {
    await pumpAboutScreen(tester, version: '2.7.0');

    expect(find.text('Flugwacht'), findsOneWidget);
    expect(find.textContaining('2.7.0'), findsOneWidget);
  });

  testWidgets('credits only the selectable sources with their licenses', (
    tester,
  ) async {
    await pumpAboutScreen(tester);

    final sources = textContaining(tester, 'ODbL');
    expect(sources, contains('adsb.lol (ODbL)'));
    expect(sources, contains('adsb.fi'));
    expect(sources, isNot(contains('airplanes.live')));
  });

  testWidgets('attributes the map and the icons', (tester) async {
    await pumpAboutScreen(tester);

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('Font Awesome Pro'), findsOneWidget);
  });

  testWidgets('opens the license page from its row', (tester) async {
    await pumpAboutScreen(tester);

    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('opens the boundfox site from the branding row', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.tap(find.text('A project by Boundfox Studios'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://boundfoxstudios.com']);
  });

  testWidgets('opens the repository from the github row', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.tap(find.text('Flugwacht on GitHub'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://github.com/BoundfoxStudios/flugwacht']);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpAboutScreen(tester, locale: const Locale('de'));

    expect(find.text('Ein Projekt von Boundfox Studios'), findsOneWidget);
    expect(find.text('Open-Source-Lizenzen'), findsOneWidget);
    expect(find.text('Flugwacht auf GitHub'), findsOneWidget);
  });
}
