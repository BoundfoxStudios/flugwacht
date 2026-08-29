import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/onboarding/route_artwork.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/rendered_pixels.dart';

const _artworkKey = ValueKey('artwork');
const _artworkSize = Size(320, 280);
const _sampleStep = 2;

ThemeData themeOf(Brightness brightness) => switch (brightness) {
  Brightness.light => buildLightTheme(),
  Brightness.dark => buildDarkTheme(),
};

Future<RenderedPixels> renderArtwork(
  WidgetTester tester,
  RouteArtworkState state, {
  Brightness brightness = Brightness.dark,
}) async {
  final theme = themeOf(brightness);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _artworkKey,
            child: ColoredBox(
              // The band the page paints the scene onto; sampling against the
              // scaffold instead would count a line that no one can see.
              color: theme.colorScheme.surface,
              child: SizedBox.fromSize(
                size: _artworkSize,
                child: RouteArtwork(state: state),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return renderedPixels(tester, _artworkKey);
}

/// How many samples across the band differ from the given colour.
int coverageOf(RenderedPixels pixels, Color color) {
  var covered = 0;
  for (var y = 0.0; y < _artworkSize.height; y += _sampleStep) {
    for (var x = 0.0; x < _artworkSize.width; x += _sampleStep) {
      if (pixels.matches(Offset(x, y), color)) {
        covered++;
      }
    }
  }
  return covered;
}

void main() {
  testWidgets('marks the live position in the accent colour', (tester) async {
    final pixels = await renderArtwork(tester, RouteArtworkState.live);

    expect(coverageOf(pixels, AppColors.amber), greaterThan(0));
  });

  testWidgets('keeps the accent out of the resting scene', (tester) async {
    final pixels = await renderArtwork(tester, RouteArtworkState.resting);

    expect(
      coverageOf(pixels, AppColors.amber),
      0,
      reason: 'yellow is what tells a live flight from one at rest',
    );
  });

  testWidgets('stays visible on its band in both themes and states', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final band = themeOf(brightness).colorScheme.surface;
      for (final state in RouteArtworkState.values) {
        final pixels = await renderArtwork(
          tester,
          state,
          brightness: brightness,
        );
        final samples =
            (_artworkSize.width / _sampleStep) *
            (_artworkSize.height / _sampleStep);

        expect(
          coverageOf(pixels, band),
          lessThan(samples),
          reason: '$state vanishes into the $brightness band',
        );
      }
    }
  });

  testWidgets('survives a box with no room for the route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox.fromSize(
              size: Size.zero,
              child: const RouteArtwork(state: RouteArtworkState.live),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
