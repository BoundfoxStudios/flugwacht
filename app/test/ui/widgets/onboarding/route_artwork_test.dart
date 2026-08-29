import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/onboarding/route_artwork.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/rendered_pixels.dart';

const _artworkKey = ValueKey('artwork');
const _artworkSize = Size(320, 280);
const _sampleStep = 2;

Future<RenderedPixels> renderArtwork(
  WidgetTester tester,
  RouteArtworkState state, {
  Brightness brightness = Brightness.dark,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _artworkKey,
            child: SizedBox.fromSize(
              size: _artworkSize,
              child: RouteArtwork(state: state),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return renderedPixels(tester, _artworkKey);
}

/// How much of the scene is painted in the accent, sampled across the whole
/// band. Only the solid fills match exactly; a ring fades into its ground.
int accentCoverage(RenderedPixels pixels) {
  var covered = 0;
  for (var y = 0.0; y < _artworkSize.height; y += _sampleStep) {
    for (var x = 0.0; x < _artworkSize.width; x += _sampleStep) {
      if (pixels.matches(Offset(x, y), AppColors.amber)) {
        covered++;
      }
    }
  }
  return covered;
}

void main() {
  testWidgets('marks the live position in the accent colour', (tester) async {
    final pixels = await renderArtwork(tester, RouteArtworkState.live);

    expect(accentCoverage(pixels), greaterThan(0));
  });

  testWidgets('keeps the accent out of the resting scene', (tester) async {
    final pixels = await renderArtwork(tester, RouteArtworkState.resting);

    expect(
      accentCoverage(pixels),
      0,
      reason: 'yellow is what tells a live flight from one at rest',
    );
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

  testWidgets('paints the route in both themes', (tester) async {
    for (final brightness in Brightness.values) {
      final pixels = await renderArtwork(
        tester,
        RouteArtworkState.resting,
        brightness: brightness,
      );
      final ground = switch (brightness) {
        Brightness.light => AppColors.neutral50,
        Brightness.dark => AppColors.neutral900,
      };

      var painted = 0;
      for (var x = 0.0; x < _artworkSize.width; x += _sampleStep) {
        for (var y = 0.0; y < _artworkSize.height; y += _sampleStep) {
          if (!pixels.matches(Offset(x, y), ground)) {
            painted++;
          }
        }
      }

      expect(painted, greaterThan(0), reason: '$brightness leaves the scene');
    }
  });
}
