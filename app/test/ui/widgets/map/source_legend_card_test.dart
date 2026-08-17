import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/map/source_legend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpLegendCard(
  WidgetTester tester, {
  required Set<SourceId> trailSourceIds,
  SourceId activeId = SourceId.adsblol,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: Scaffold(
        body: SourceLegendCard(
          trailSourceIds: trailSourceIds,
          activeId: activeId,
        ),
      ),
    ),
  );
}

bool paintsSwatch(WidgetTester tester, Color color) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .any(
      (box) =>
          box.decoration is BoxDecoration &&
          (box.decoration as BoxDecoration).color == color,
    );

void main() {
  testWidgets('lists the sources of the trail plus the active one', (
    tester,
  ) async {
    await pumpLegendCard(
      tester,
      trailSourceIds: {SourceId.adsbfi},
      activeId: SourceId.adsblol,
    );

    expect(find.text('TRAIL BY SOURCE'), findsOneWidget);
    expect(find.text('adsb.lol'), findsOneWidget);
    expect(find.text('adsb.fi'), findsOneWidget);
    expect(find.text('airplanes.live'), findsNothing);
  });

  testWidgets('lists the sources in the order of the source list', (
    tester,
  ) async {
    await pumpLegendCard(
      tester,
      trailSourceIds: {SourceId.airplanes, SourceId.adsbfi},
      activeId: SourceId.adsblol,
    );

    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList(),
      containsAllInOrder(['adsb.lol', 'adsb.fi', 'airplanes.live']),
    );
  });

  testWidgets('marks the source the app is polling', (tester) async {
    await pumpLegendCard(
      tester,
      trailSourceIds: {SourceId.adsblol, SourceId.adsbfi},
      activeId: SourceId.adsbfi,
    );

    expect(find.text('active'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('adsb.fi')).style?.fontWeight,
      FontWeight.w600,
    );
    expect(
      tester.widget<Text>(find.text('adsb.lol')).style?.fontWeight,
      isNot(FontWeight.w600),
    );
  });

  testWidgets('paints every row in the trail color of its source', (
    tester,
  ) async {
    await pumpLegendCard(
      tester,
      trailSourceIds: {SourceId.adsblol, SourceId.adsbfi, SourceId.airplanes},
    );

    expect(paintsSwatch(tester, AppColors.amber), isTrue);
    expect(paintsSwatch(tester, AppColors.orange), isTrue);
    expect(paintsSwatch(tester, AppColors.neutral500), isTrue);
  });

  testWidgets('paints airplanes.live for the dark theme', (tester) async {
    await pumpLegendCard(
      tester,
      trailSourceIds: {SourceId.adsblol, SourceId.airplanes},
      brightness: Brightness.dark,
    );

    expect(paintsSwatch(tester, AppColors.neutral300), isTrue);
  });

  testWidgets('titles and marks the active source in German as well', (
    tester,
  ) async {
    await pumpLegendCard(
      tester,
      trailSourceIds: {SourceId.adsblol, SourceId.adsbfi},
      locale: const Locale('de'),
    );

    expect(find.text('SPUR JE QUELLE'), findsOneWidget);
    expect(find.text('aktiv'), findsOneWidget);
  });
}
