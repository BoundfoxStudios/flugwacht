import 'dart:typed_data';

import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/branding/radar_eye_logo.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _logoKey = ValueKey('logo');
const _logoSize = 76.0;

/// Inside the iris, clear of the radar wedge, the ring and the eye outline.
const _irisPixel = Offset(30, 46);

/// The left tip of the eye outline, where the stroke is at its thickest.
const _outlinePixel = Offset(6, 38);

/// Inside the radar wedge, clear of the ring and the iris edge.
const _wedgePixel = Offset(43, 28);

Future<ByteData> renderLogo(WidgetTester tester, Brightness brightness) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: const Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _logoKey,
            child: RadarEyeLogo(size: _logoSize),
          ),
        ),
      ),
    ),
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_logoKey),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    return (await image.toByteData())!;
  }))!;
}

Color pixelOf(ByteData pixels, Offset point) {
  final offset = (point.dy.toInt() * _logoSize.toInt() + point.dx.toInt()) * 4;
  return Color.fromARGB(
    pixels.getUint8(offset + 3),
    pixels.getUint8(offset),
    pixels.getUint8(offset + 1),
    pixels.getUint8(offset + 2),
  );
}

void expectSameColor(Color actual, Color expected) {
  expect(
    actual.toARGB32().toRadixString(16),
    expected.toARGB32().toRadixString(16),
  );
}

void main() {
  testWidgets('paints the light variant with a dark outline and iris', (
    tester,
  ) async {
    final pixels = await renderLogo(tester, Brightness.light);

    expectSameColor(pixelOf(pixels, _irisPixel), AppColors.neutral800);
    expectSameColor(pixelOf(pixels, _outlinePixel), AppColors.neutral800);
  });

  testWidgets('paints the dark variant with a white outline and grey iris', (
    tester,
  ) async {
    final pixels = await renderLogo(tester, Brightness.dark);

    expectSameColor(pixelOf(pixels, _irisPixel), AppColors.neutral700);
    expectSameColor(pixelOf(pixels, _outlinePixel), AppColors.neutral50);
  });

  testWidgets('keeps the amber radar wedge in both themes', (tester) async {
    expectSameColor(
      pixelOf(await renderLogo(tester, Brightness.light), _wedgePixel),
      AppColors.amber,
    );
    expectSameColor(
      pixelOf(await renderLogo(tester, Brightness.dark), _wedgePixel),
      AppColors.amber,
    );
  });

  testWidgets('sizes itself as asked', (tester) async {
    await renderLogo(tester, Brightness.light);

    expect(
      tester.getSize(find.byType(RadarEyeLogo)),
      const Size.square(_logoSize),
    );
  });
}
