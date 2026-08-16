import 'package:flugwacht/app_icons.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/app_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _tabs = [
  AppTab(icon: AppIcons.map, label: 'Karte'),
  AppTab(icon: AppIcons.planeUp, label: 'Flüge'),
  AppTab(icon: AppIcons.ellipsis, label: 'Mehr'),
];

Future<List<int>> pumpTabBar(
  WidgetTester tester, {
  required ThemeData theme,
  int currentIndex = 1,
}) async {
  final selections = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        bottomNavigationBar: AppTabBar(
          tabs: _tabs,
          currentIndex: currentIndex,
          onTabSelected: selections.add,
        ),
      ),
    ),
  );
  return selections;
}

final indicator = find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      (widget.decoration as BoxDecoration?)?.color == AppColors.amber,
);

Finder tabOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Stack));

Color? labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

Color? iconColor(WidgetTester tester, String label) => tester
    .widget<FaIcon>(
      find.descendant(of: tabOf(label), matching: find.byType(FaIcon)),
    )
    .color;

void main() {
  testWidgets('only the active tab carries the indicator', (tester) async {
    await pumpTabBar(tester, theme: buildLightTheme());

    expect(indicator, findsOneWidget);
    expect(
      find.descendant(of: tabOf('Flüge'), matching: indicator),
      findsOneWidget,
    );
  });

  testWidgets('the indicator follows the current tab', (tester) async {
    await pumpTabBar(tester, theme: buildLightTheme(), currentIndex: 2);

    expect(
      find.descendant(of: tabOf('Mehr'), matching: indicator),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tabOf('Flüge'), matching: indicator),
      findsNothing,
    );
  });

  testWidgets('reports the tapped tab', (tester) async {
    final selections = await pumpTabBar(tester, theme: buildLightTheme());

    await tester.tap(find.text('Karte'));

    expect(selections, [0]);
  });

  testWidgets('renders an icon for every tab', (tester) async {
    await pumpTabBar(tester, theme: buildLightTheme());

    expect(find.byType(FaIcon), findsNWidgets(3));
    expect(
      find.descendant(
        of: tabOf('Flüge'),
        matching: find.byIcon(AppIcons.planeUp.data),
      ),
      findsOneWidget,
    );
  });

  testWidgets('light theme colors the active and inactive labels', (
    tester,
  ) async {
    await pumpTabBar(tester, theme: buildLightTheme());

    expect(labelColor(tester, 'Flüge'), AppColors.neutral800);
    expect(labelColor(tester, 'Karte'), AppColors.neutral400);
  });

  testWidgets('dark theme colors the active and inactive labels', (
    tester,
  ) async {
    await pumpTabBar(tester, theme: buildDarkTheme());

    expect(labelColor(tester, 'Flüge'), AppColors.neutral50);
    expect(labelColor(tester, 'Karte'), AppColors.neutral500);
  });

  testWidgets('an icon carries the color of its label', (tester) async {
    await pumpTabBar(tester, theme: buildLightTheme());

    expect(iconColor(tester, 'Flüge'), labelColor(tester, 'Flüge'));
    expect(iconColor(tester, 'Karte'), labelColor(tester, 'Karte'));
  });
}
