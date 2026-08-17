import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/chrome/pager_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<Color?>> pumpPagerDots(
  WidgetTester tester, {
  required int count,
  required int activeIndex,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(
        body: PagerDots(count: count, activeIndex: activeIndex),
      ),
    ),
  );
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(PagerDots),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => (box.decoration as BoxDecoration).color)
      .toList();
}

void main() {
  testWidgets('marks the page it is on', (tester) async {
    final dots = await pumpPagerDots(tester, count: 3, activeIndex: 1);

    expect(dots, [
      AppColors.neutral300,
      AppColors.neutral700,
      AppColors.neutral300,
    ]);
  });

  testWidgets('stays away while there is nothing to page through', (
    tester,
  ) async {
    final dots = await pumpPagerDots(tester, count: 1, activeIndex: 0);

    expect(dots, isEmpty);
  });
}
