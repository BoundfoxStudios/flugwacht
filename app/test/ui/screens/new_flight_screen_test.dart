import 'package:flugwacht/domain/flight.dart';
import 'package:flugwacht/l10n/app_localizations.dart';
import 'package:flugwacht/ui/screens/new_flight_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/app_primary_button.dart';
import 'package:flugwacht/ui/widgets/app_segmented_control.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpNewFlightScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  TargetPlatform platform = TargetPlatform.android,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme().copyWith(platform: platform),
      home: NewFlightScreen(today: DateTime(2026, 8, 12)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapSegment(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AppSegmentedControl<FlightLookupKind>),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enterLookupValue(WidgetTester tester, String value) async {
  await tester.enterText(find.byType(TextField).first, value);
  await tester.pumpAndSettle();
}

VoidCallback? submitCallback(WidgetTester tester) =>
    tester.widget<AppPrimaryButton>(find.byType(AppPrimaryButton)).onPressed;

void main() {
  testWidgets('swaps hint and validation with the selected segment', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    expect(find.text('As printed on your ticket, e.g. LH 400'), findsOneWidget);

    await tapSegment(tester, 'Registration');

    expect(
      find.text('The registration of the aircraft, e.g. D-AIMA'),
      findsOneWidget,
    );
    expect(find.text('As printed on your ticket, e.g. LH 400'), findsNothing);
  });

  testWidgets('keeps the value of every segment while switching', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);
    await enterLookupValue(tester, 'LH 400');

    await tapSegment(tester, 'Registration');
    await enterLookupValue(tester, 'D-AIMA');
    await tapSegment(tester, 'Flight number');

    expect(find.text('LH 400'), findsOneWidget);

    await tapSegment(tester, 'Registration');

    expect(find.text('D-AIMA'), findsOneWidget);
  });

  testWidgets('enables the button only for a parseable flight number', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'LH');

    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'LH 400');

    expect(submitCallback(tester), isNotNull);
  });

  testWidgets('enables the button only for a registration of allowed shape', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);
    await tapSegment(tester, 'Registration');

    await enterLookupValue(tester, 'D');
    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'D-AIMA');
    expect(submitCallback(tester), isNotNull);
  });

  testWidgets('enables the button only for six hex digits', (tester) async {
    await pumpNewFlightScreen(tester);
    await tapSegment(tester, 'Hex');

    await enterLookupValue(tester, '3C64');
    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, 'XYZXYZ');
    expect(submitCallback(tester), isNull);

    await enterLookupValue(tester, '3C6444');
    expect(submitCallback(tester), isNotNull);
  });

  testWidgets('shows the low cost carrier hint for their flight numbers only', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);
    final hint = find.textContaining('Ryanair, easyJet and Wizz Air');

    await enterLookupValue(tester, 'LH 400');
    expect(hint, findsNothing);

    await enterLookupValue(tester, 'FR 1234');
    expect(hint, findsOneWidget);

    await tapSegment(tester, 'Hex');
    expect(hint, findsNothing);
  });

  testWidgets('opens the material date picker within the allowed range', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await tester.tap(find.text('Wed, August 12, 2026'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(dialog.initialDate, DateTime(2026, 8, 12));
    expect(dialog.firstDate, DateTime(2026, 8, 11));
    expect(dialog.lastDate, DateTime(2027, 8, 12));
  });

  testWidgets('shows the picked date in the departure date field', (
    tester,
  ) async {
    await pumpNewFlightScreen(tester);

    await tester.tap(find.text('Wed, August 12, 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Thu, August 20, 2026'), findsOneWidget);
  });

  testWidgets('opens the cupertino date picker on ios', (tester) async {
    await pumpNewFlightScreen(tester, platform: TargetPlatform.iOS);

    await tester.tap(find.text('Wed, August 12, 2026'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('renders the german copy for a german locale', (tester) async {
    await pumpNewFlightScreen(tester, locale: const Locale('de'));

    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Wie auf dem Ticket, z. B. LH 400'), findsOneWidget);
    expect(find.text('Mi., 12. August 2026'), findsOneWidget);
    expect(find.text('Flug eintragen'), findsOneWidget);
  });
}
