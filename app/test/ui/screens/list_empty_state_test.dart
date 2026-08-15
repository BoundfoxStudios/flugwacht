import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/list_empty_state.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/app_primary_button.dart';
import 'package:flugwacht/ui/widgets/radar_eye_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpEmptyState(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  VoidCallback? onAddFlight,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildLightTheme(),
    home: Scaffold(body: ListEmptyState(onAddFlight: onAddFlight ?? () {})),
  ),
);

void main() {
  testWidgets('shows logo, headline, copy and call to action', (tester) async {
    await pumpEmptyState(tester);

    expect(find.byType(RadarEyeLogo), findsOneWidget);
    expect(find.text('No flight\non the list yet'), findsOneWidget);
    expect(
      find.text(
        'Add a flight — Flugwacht tracks it automatically on its flight '
        'day and shows you when it arrives.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AppPrimaryButton), findsOneWidget);
    expect(find.text('Add flight'), findsOneWidget);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpEmptyState(tester, locale: const Locale('de'));

    expect(find.text('Noch kein Flug\nauf der Liste'), findsOneWidget);
    expect(find.text('Flug eintragen'), findsOneWidget);
  });

  testWidgets('reports a tap on the call to action', (tester) async {
    var taps = 0;
    await pumpEmptyState(tester, onAddFlight: () => taps++);

    await tester.tap(find.byType(AppPrimaryButton));

    expect(taps, 1);
  });

  testWidgets('scrolls instead of overflowing on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpEmptyState(tester);

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(RadarEyeLogo), const Offset(0, -80));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
