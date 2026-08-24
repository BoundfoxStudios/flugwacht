import 'package:flugwacht/data/settings/source_setting.dart';
import 'package:flugwacht/data/settings/units_setting.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/units.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/more_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/controls/app_radio_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_dependencies.dart';

Future<({SourceSetting source, UnitsSetting units})> pumpMoreScreen(
  WidgetTester tester, {
  String version = '1.4.2',
  Locale locale = const Locale('en'),
}) async {
  final sourceSetting = await createTestSourceSetting();
  final unitsSetting = await createTestUnitsSetting();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: MoreScreen(
        sourceSetting: sourceSetting,
        unitsSetting: unitsSetting,
        packageInfo: testPackageInfo(version: version),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (source: sourceSetting, units: unitsSetting);
}

bool isSelected(WidgetTester tester, String label) => tester
    .widget<AppRadioRow>(find.widgetWithText(AppRadioRow, label))
    .isSelected;

void main() {
  testWidgets('offers the selectable sources with the active one marked', (
    tester,
  ) async {
    await pumpMoreScreen(tester);

    expect(find.byType(AppRadioRow), findsNWidgets(selectableSourceIds.length));
    expect(find.text('adsb.lol'), findsOneWidget);
    expect(find.text('adsb.fi'), findsOneWidget);
    expect(find.text('airplanes.live'), findsNothing);
    expect(isSelected(tester, 'adsb.lol'), isTrue);
    expect(isSelected(tester, 'adsb.fi'), isFalse);
  });

  testWidgets('selecting another source persists it and marks its row', (
    tester,
  ) async {
    final settings = await pumpMoreScreen(tester);

    await tester.tap(find.text('adsb.fi'));
    await tester.pumpAndSettle();

    expect(settings.source.activeId.value, SourceId.adsbfi);
    expect(isSelected(tester, 'adsb.fi'), isTrue);
    expect(isSelected(tester, 'adsb.lol'), isFalse);
  });

  testWidgets('switches the units the app displays', (tester) async {
    final settings = await pumpMoreScreen(tester);

    await tester.tap(find.text('Aviation (ft, kt)'));
    await tester.pumpAndSettle();

    expect(settings.units.units.value, Units.aviation);
  });

  testWidgets('leaves the notification switches to their own page', (
    tester,
  ) async {
    await pumpMoreScreen(tester);

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Landed'), findsNothing);
    expect(find.text('Remind me on the flight day'), findsNothing);
  });

  testWidgets('names the app version below the about entry', (tester) async {
    await pumpMoreScreen(tester, version: '2.7.0');

    expect(find.textContaining('2.7.0'), findsOneWidget);
  });

  testWidgets('offers the notifications and the faq above the about entry', (
    tester,
  ) async {
    await pumpMoreScreen(tester);

    final about = tester.getTopLeft(find.text('About Flugwacht')).dy;
    expect(tester.getTopLeft(find.text('Notifications')).dy, lessThan(about));
    expect(
      tester.getTopLeft(find.text('Frequently asked questions')).dy,
      lessThan(about),
    );
  });
}
