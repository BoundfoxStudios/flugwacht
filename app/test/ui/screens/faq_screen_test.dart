import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/faq_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/chrome/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpFaqScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: const FaqScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapQuestion(WidgetTester tester, String question) async {
  final finder = find.text(question);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const _questions = [
  'Why does the data differ from FlightRadar24 and others?',
  'Why is the arrival time sometimes inaccurate?',
  'Why does the trail only start when I add the flight?',
  'Why can I not find my flight?',
  'Why does the trail have gaps?',
  'Why do flights disappear after landing?',
  'Why does a notification sometimes arrive late?',
  'Where does the data come from?',
  'Do I need an account?',
];

void main() {
  testWidgets('lists every question with its answer folded away', (
    tester,
  ) async {
    await pumpFaqScreen(tester);

    for (final question in _questions) {
      expect(find.text(question), findsOneWidget, reason: question);
    }
    expect(find.byType(SettingsCard), findsNWidgets(_questions.length));
    expect(find.textContaining('no schedule-based guesses'), findsNothing);
  });

  testWidgets('unfolds an answer and folds it away again', (tester) async {
    await pumpFaqScreen(tester);

    await tapQuestion(tester, _questions.first);

    expect(find.textContaining('no schedule-based guesses'), findsOneWidget);

    await tapQuestion(tester, _questions.first);

    expect(find.textContaining('no schedule-based guesses'), findsNothing);
  });

  testWidgets('keeps two answers open at the same time', (tester) async {
    await pumpFaqScreen(tester);

    await tapQuestion(tester, _questions.first);
    await tapQuestion(tester, _questions.last);

    expect(find.textContaining('no schedule-based guesses'), findsOneWidget);
    expect(find.textContaining('no server, no sign-up'), findsOneWidget);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpFaqScreen(tester, locale: const Locale('de'));

    expect(find.text('Brauche ich ein Konto?'), findsOneWidget);

    await tapQuestion(tester, 'Brauche ich ein Konto?');

    expect(find.textContaining('kein Server'), findsOneWidget);
  });
}
