import 'package:flugwacht/app_icons.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/map/map_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpMapButton(
  WidgetTester tester, {
  required Brightness brightness,
  VoidCallback? onPressed,
}) => tester.pumpWidget(
  MaterialApp(
    theme: switch (brightness) {
      Brightness.light => buildLightTheme(),
      Brightness.dark => buildDarkTheme(),
    },
    home: Scaffold(
      body: MapButton(
        icon: AppIcons.layerGroup,
        semanticsLabel: 'Switch map style',
        onPressed: onPressed ?? () {},
      ),
    ),
  ),
);

BoxDecoration decorationOf(WidgetTester tester) =>
    tester.widget<Container>(find.byType(Container)).decoration!
        as BoxDecoration;

void main() {
  testWidgets('carries the light chrome on the light theme', (tester) async {
    await pumpMapButton(tester, brightness: Brightness.light);

    final decoration = decorationOf(tester);
    expect(decoration.color, AppColors.white);
    expect(decoration.border, Border.all(color: AppColors.neutral200));
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('carries the dark chrome on the dark theme', (tester) async {
    await pumpMapButton(tester, brightness: Brightness.dark);

    final decoration = decorationOf(tester);
    expect(decoration.color, AppColors.neutral800);
    expect(decoration.border, Border.all(color: AppColors.neutral700));
    expect(decoration.boxShadow, isEmpty);
  });

  testWidgets('keeps the 44 px minimum hit target', (tester) async {
    await pumpMapButton(tester, brightness: Brightness.light);

    expect(tester.getSize(find.byType(MapButton)), const Size(44, 44));
  });

  testWidgets('reports a tap to its owner', (tester) async {
    var taps = 0;
    await pumpMapButton(
      tester,
      brightness: Brightness.light,
      onPressed: () => taps++,
    );

    await tester.tap(find.byType(MapButton));

    expect(taps, 1);
  });
}
