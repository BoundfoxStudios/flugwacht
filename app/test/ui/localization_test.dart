import 'package:flugwacht/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_dependencies.dart';

Future<void> pumpAppWithDeviceLocales(
  WidgetTester tester,
  List<Locale> locales,
) async {
  tester.platformDispatcher.localesTestValue = locales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(FlugwachtApp(router: createTestAppRouter()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows German copy when the device language is German', (
    tester,
  ) async {
    await pumpAppWithDeviceLocales(tester, const [Locale('de')]);

    expect(find.text('Karte'), findsOneWidget);
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Mehr'), findsOneWidget);
  });

  testWidgets('falls back to English when the device language is unsupported', (
    tester,
  ) async {
    await pumpAppWithDeviceLocales(tester, const [Locale('fr')]);

    expect(find.text('Map'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });
}
