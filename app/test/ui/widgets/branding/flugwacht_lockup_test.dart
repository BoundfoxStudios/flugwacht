import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/branding/flugwacht_lockup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/rendered_pixels.dart';

const _lockupKey = ValueKey('lockup');

/// The master is 231.18 by 42, so rendering it at its own height lets the
/// points below name the coordinates its paths are written in.
const _lockupHeight = 42.0;

/// Inside the stem of the F, clear of the letter's edges.
const _wordmarkPixel = Offset(59, 30);

/// Inside the iris, below left of the pupil and clear of the radar wedge.
const _irisPixel = Offset(18, 24);

/// Inside the radar wedge, clear of the pupil and the iris edge.
const _wedgePixel = Offset(23, 18);

Future<RenderedPixels> renderLockup(
  WidgetTester tester,
  Brightness brightness,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: const Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _lockupKey,
            child: FlugwachtLockup(height: _lockupHeight),
          ),
        ),
      ),
    ),
  );
  return renderedPixels(tester, _lockupKey);
}

void expectSameColor(RenderedPixels pixels, Offset point, Color expected) =>
    expect(
      pixels.at(point).toARGB32().toRadixString(16),
      expected.toARGB32().toRadixString(16),
    );

void main() {
  testWidgets('paints the light master with its dark ink', (tester) async {
    final pixels = await renderLockup(tester, Brightness.light);

    expectSameColor(pixels, _wordmarkPixel, AppColors.neutral800);
    expectSameColor(pixels, _irisPixel, AppColors.neutral800);
  });

  testWidgets('paints the dark master with its light ink', (tester) async {
    final pixels = await renderLockup(tester, Brightness.dark);

    expectSameColor(pixels, _wordmarkPixel, AppColors.neutral50);
    expectSameColor(pixels, _irisPixel, AppColors.neutral700);
  });

  testWidgets('keeps the amber radar wedge in both themes', (tester) async {
    expectSameColor(
      await renderLockup(tester, Brightness.light),
      _wedgePixel,
      AppColors.amber,
    );
    expectSameColor(
      await renderLockup(tester, Brightness.dark),
      _wedgePixel,
      AppColors.amber,
    );
  });
}
