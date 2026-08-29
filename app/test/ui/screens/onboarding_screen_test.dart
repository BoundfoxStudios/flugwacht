import 'package:flugwacht/l10n/app_localization_delegates.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/onboarding_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/controls/app_primary_button.dart';
import 'package:flugwacht/ui/widgets/onboarding/route_artwork.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const purposeTitle = 'What Flugwacht\ndoes';
const limitsTitle = 'What Flugwacht\ncannot do';
const openSourceTitle = 'Open and\nopen source';

Future<void> pumpOnboarding(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  VoidCallback? onDone,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: OnboardingScreen(onDone: onDone ?? () {}),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapButton(WidgetTester tester) async {
  await tester.tap(find.byType(AppPrimaryButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on what the app does, with a way on', (tester) async {
    await pumpOnboarding(tester);

    expect(find.text(purposeTitle), findsOneWidget);
    expect(find.text('Live flight tracking on the map.'), findsOneWidget);
    expect(find.text('No ads, no premium features.'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text(limitsTitle), findsNothing);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpOnboarding(tester, locale: const Locale('de'));

    expect(find.text('Das macht\nFlugwacht'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
  });

  testWidgets('the button pages on until the last page', (tester) async {
    await pumpOnboarding(tester);

    await tapButton(tester);
    expect(find.text(limitsTitle), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tapButton(tester);
    expect(find.text(openSourceTitle), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('the last page hands the app over instead of paging', (
    tester,
  ) async {
    var handovers = 0;
    await pumpOnboarding(tester, onDone: () => handovers++);

    await tapButton(tester);
    await tapButton(tester);
    await tapButton(tester);

    expect(handovers, 1);
    expect(find.text(openSourceTitle), findsOneWidget);
  });

  testWidgets('swiping moves to the next page', (tester) async {
    await pumpOnboarding(tester);

    await tester.fling(find.text(purposeTitle), const Offset(-400, 0), 800);
    await tester.pumpAndSettle();

    expect(find.text(limitsTitle), findsOneWidget);
  });

  testWidgets('swiping back on the first page stays there', (tester) async {
    await pumpOnboarding(tester);

    await tester.fling(find.text(purposeTitle), const Offset(400, 0), 800);
    await tester.pumpAndSettle();

    expect(find.text(purposeTitle), findsOneWidget);
    expect(find.text(openSourceTitle), findsNothing);
  });

  testWidgets('a tapped page dot jumps to its page', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.bySemanticsLabel('Page 3 of 3'));
    await tester.pumpAndSettle();

    expect(find.text(openSourceTitle), findsOneWidget);
  });

  testWidgets('the dot of the current page is the wider one', (tester) async {
    await pumpOnboarding(tester);

    Size dotSize(int page) => tester.getSize(
      find.descendant(
        of: find.bySemanticsLabel('Page $page of 3'),
        matching: find.byType(AnimatedContainer),
      ),
    );

    expect(dotSize(1).width, greaterThan(dotSize(2).width));
  });

  testWidgets('each of the three pages carries its own artwork', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    expect(
      tester.widget<RouteArtwork>(find.byType(RouteArtwork)).state,
      RouteArtworkState.live,
    );

    await tapButton(tester);

    expect(
      tester.widget<RouteArtwork>(find.byType(RouteArtwork)).state,
      RouteArtworkState.resting,
    );

    await tapButton(tester);

    expect(find.byType(RouteArtwork), findsNothing);
  });

  testWidgets('scrolls instead of overflowing on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpOnboarding(tester);

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(RouteArtwork), const Offset(0, -120));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
