import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpTabBar(
  WidgetTester tester, {
  required ThemeData theme,
  int currentIndex = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        bottomNavigationBar: AppTabBar(
          labels: const ['Karte', 'Liste', 'Mehr'],
          currentIndex: currentIndex,
          onTabSelected: (_) {},
        ),
      ),
    ),
  );
}

final indicator = find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      (widget.decoration as BoxDecoration?)?.color == AppColors.amber,
);

Color? labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  testWidgets('only the active tab carries the indicator', (tester) async {
    await pumpTabBar(tester, theme: buildLightTheme());

    expect(indicator, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Liste'), matching: find.byType(Stack)),
        matching: indicator,
      ),
      findsOneWidget,
    );
  });

  testWidgets('light theme colors the active and inactive labels', (
    tester,
  ) async {
    await pumpTabBar(tester, theme: buildLightTheme());

    expect(labelColor(tester, 'Liste'), AppColors.neutral800);
    expect(labelColor(tester, 'Karte'), AppColors.neutral400);
  });

  testWidgets('dark theme colors the active and inactive labels', (
    tester,
  ) async {
    await pumpTabBar(tester, theme: buildDarkTheme());

    expect(labelColor(tester, 'Liste'), AppColors.neutral50);
    expect(labelColor(tester, 'Karte'), AppColors.neutral500);
  });
}
