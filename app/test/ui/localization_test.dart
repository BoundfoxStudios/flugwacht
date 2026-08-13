import 'package:flugwacht/main.dart';
import 'package:flugwacht/ui/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpAppWithDeviceLocales(
  WidgetTester tester,
  List<Locale> locales,
) async {
  tester.platformDispatcher.localesTestValue = locales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(FlugwachtApp(router: createAppRouter()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows German copy when the device language is German', (
    tester,
  ) async {
    await pumpAppWithDeviceLocales(tester, const [Locale('de')]);

    expect(find.text('Karte'), findsNWidgets(2));
    expect(find.text('Liste'), findsOneWidget);
    expect(find.text('Mehr'), findsOneWidget);
  });

  testWidgets('falls back to English when the device language is unsupported', (
    tester,
  ) async {
    await pumpAppWithDeviceLocales(tester, const [Locale('fr')]);

    expect(find.text('Map'), findsNWidgets(2));
    expect(find.text('List'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });
}
