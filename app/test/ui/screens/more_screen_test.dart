import 'package:flugwacht/data/source_setting.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/more_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/app_radio_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

Future<SourceSetting> pumpMoreScreen(
  WidgetTester tester, {
  String version = '1.4.2',
  Locale locale = const Locale('en'),
}) async {
  final sourceSetting = await createTestSourceSetting();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: MoreScreen(
        sourceSetting: sourceSetting,
        packageInfo: testPackageInfo(version: version),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return sourceSetting;
}

bool isSelected(WidgetTester tester, String label) => tester
    .widget<AppRadioRow>(find.widgetWithText(AppRadioRow, label))
    .isSelected;

String textContaining(WidgetTester tester, String fragment) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .firstWhere((data) => data.contains(fragment));

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
    final sourceSetting = await pumpMoreScreen(tester);

    await tester.tap(find.text('adsb.fi'));
    await tester.pumpAndSettle();

    expect(sourceSetting.activeId.value, SourceId.adsbfi);
    expect(isSelected(tester, 'adsb.fi'), isTrue);
    expect(isSelected(tester, 'adsb.lol'), isFalse);
  });

  testWidgets('names the app version below the about entry', (tester) async {
    await pumpMoreScreen(tester, version: '2.7.0');

    expect(find.textContaining('2.7.0'), findsOneWidget);
  });

  testWidgets('credits only the selectable sources in the data footnote', (
    tester,
  ) async {
    await pumpMoreScreen(tester);

    final footnote = textContaining(tester, 'ODbL');
    expect(footnote, contains('adsb.lol (ODbL)'));
    expect(footnote, contains('adsb.fi'));
    expect(footnote, isNot(contains('airplanes.live')));
    expect(footnote, contains('OpenStreetMap'));
  });
}
