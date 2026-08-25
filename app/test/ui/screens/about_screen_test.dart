import 'package:flugwacht/l10n/app_localization_delegates.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/about_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/branding/flugwacht_lockup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_dependencies.dart';

Future<FakeUrlLauncher> pumpAboutScreen(
  WidgetTester tester, {
  String version = '1.4.2',
  String buildNumber = '1',
  Locale locale = const Locale('en'),
}) async {
  final launcher = createTestUrlLauncher();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: AboutScreen(
        packageInfo: testPackageInfo(
          version: version,
          buildNumber: buildNumber,
        ),
      ),
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
  testWidgets('heads the screen with the lockup and the installed version', (
    tester,
  ) async {
    await pumpAboutScreen(tester, version: '2.7.0');

    expect(find.byType(FlugwachtLockup), findsOneWidget);
    expect(find.textContaining('2.7.0'), findsOneWidget);
  });

  /// Two builds of the same version are only told apart by the build number,
  /// and a device shows it nowhere else.
  testWidgets('names the build the version was cut from', (tester) async {
    await pumpAboutScreen(tester, version: '2.7.0', buildNumber: '148');

    expect(textContaining(tester, '2.7.0'), contains('148'));
  });

  testWidgets('credits only the selectable sources with their licenses', (
    tester,
  ) async {
    await pumpAboutScreen(tester);

    expect(find.text('adsb.lol (ODbL)'), findsOneWidget);
    expect(find.text('adsb.fi'), findsOneWidget);
    expect(find.textContaining('airplanes.live'), findsNothing);
  });

  testWidgets('attributes the map and the icons', (tester) async {
    await pumpAboutScreen(tester);

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('Font Awesome Pro'), findsOneWidget);
  });

  testWidgets('opens the site of a source from its credit', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.tap(find.text('adsb.lol (ODbL)'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://adsb.lol']);
  });

  /// adsb.fi answers under opendata.adsb.fi, so its credit is the one that
  /// would go to the API host if the rows ever took the polled URL.
  testWidgets('leads to the source project rather than the host it polls', (
    tester,
  ) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.tap(find.text('adsb.fi'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://adsb.fi']);
  });

  testWidgets('opens the map copyright page from its credit', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.tap(find.text('Map © OpenStreetMap contributors'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://www.openstreetmap.org/copyright']);
  });

  testWidgets('opens the license page from its row', (tester) async {
    await pumpAboutScreen(tester);

    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('opens the boundfox site from the branding row', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.ensureVisible(find.text('A project by Boundfox Studios'));
    await tester.tap(find.text('A project by Boundfox Studios'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://boundfoxstudios.com']);
  });

  testWidgets('opens the repository from the github row', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.ensureVisible(find.text('Flugwacht on GitHub'));
    await tester.tap(find.text('Flugwacht on GitHub'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://github.com/BoundfoxStudios/flugwacht']);
  });

  testWidgets('opens the discord invite from its row', (tester) async {
    final launcher = await pumpAboutScreen(tester);

    await tester.ensureVisible(find.text('Join Flugwacht on Discord'));
    await tester.tap(find.text('Join Flugwacht on Discord'));
    await tester.pumpAndSettle();

    expect(launcher.launched, ['https://discord.gg/tHqNzMT']);
  });

  testWidgets('asks the store for its page and swallows a refusal', (
    tester,
  ) async {
    final storeRequests = <Object?>[];
    // Answering null makes pigeon raise its channel error, which is the
    // ReviewEtiquetteException path the row is expected to swallow.
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.review_etiquette.ReviewEtiquetteHostApi.openStoreListing',
      (message) async {
        storeRequests.add(message);
        return null;
      },
    );
    await pumpAboutScreen(tester);

    await tester.ensureVisible(find.text('Rate Flugwacht'));
    await tester.tap(find.text('Rate Flugwacht'));
    await tester.pumpAndSettle();

    expect(storeRequests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpAboutScreen(tester, locale: const Locale('de'));

    expect(find.text('Ein Projekt von Boundfox Studios'), findsOneWidget);
    expect(find.text('Open-Source-Lizenzen'), findsOneWidget);
    expect(find.text('Bewerte Flugwacht'), findsOneWidget);
    expect(find.text('Flugwacht auf GitHub'), findsOneWidget);
    expect(find.text('Tritt der Discord Community bei'), findsOneWidget);
    expect(find.text('Karte © OpenStreetMap-Mitwirkende'), findsOneWidget);
    expect(find.textContaining('ohne Gewähr'), findsOneWidget);
  });
}
