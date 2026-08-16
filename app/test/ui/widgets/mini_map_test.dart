import 'dart:math';

import 'package:flugwacht/data/map_style_setting.dart';
import 'package:flugwacht/domain/fix.dart';
import 'package:flugwacht/domain/flight_route.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/domain/map_style.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/trail_point.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/mini_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../support/rendered_pixels.dart';
import '../../support/test_dependencies.dart';

const _mapKey = ValueKey('map');
const _mapSize = Size(300, 150);
const _mapCenter = Offset(150, 75);
const _ringRadius = 14.0;

FixPosition position({double latitude = 48.5, double longitude = -20}) =>
    FixPosition(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.utc(2026, 8, 12, 12),
      trackDegrees: 271.4,
    );

TrailPoint trailPoint(double latitude, double longitude) => TrailPoint(
  timestamp: DateTime.utc(2026, 8, 12, 11),
  latitude: latitude,
  longitude: longitude,
  sourceId: SourceId.adsblol,
);

Future<void> pumpMiniMap(
  WidgetTester tester, {
  required FixPosition at,
  FlightState state = FlightState.live,
  FlightRoute? route,
  List<TrailPoint> trail = const [],
  Brightness brightness = Brightness.light,
  bool withVectorTiles = false,
  MapStyleSetting? mapStyleSetting,
}) async {
  final styleSetting = mapStyleSetting ?? await createTestMapStyleSetting();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: switch (brightness) {
        Brightness.light => buildLightTheme(),
        Brightness.dark => buildDarkTheme(),
      },
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _mapKey,
            child: SizedBox.fromSize(
              size: _mapSize,
              child: MiniMap(
                position: at,
                route: route,
                trail: trail,
                state: state,
                mapStyleSetting: styleSetting,
                tileSources: testTileSources(withVectorTiles: withVectorTiles),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (withVectorTiles) {
    // The vector layer schedules its cache housekeeping three seconds out.
    await tester.pump(const Duration(seconds: 3));
  }
}

/// The amber of a live aircraft, tolerant of the contour anti-aliasing that
/// blends into the pixel at its centre.
void expectAmberAircraft(RenderedPixels pixels) {
  final color = pixels.at(_mapCenter);
  expect(color.r, greaterThan(0.8), reason: 'amber is red-heavy');
  expect(color.b, lessThan(0.3), reason: 'amber carries almost no blue');
}

/// The grey of an aircraft without a signal: all channels alike, and darker
/// than the map ground.
void expectGrayAircraft(RenderedPixels pixels) {
  final color = pixels.at(_mapCenter);
  expect((color.r - color.b).abs(), lessThan(0.05), reason: 'grey is neutral');
  expect(color.r, lessThan(0.9), reason: 'darker than the map ground');
}

/// How much of the ring around the aircraft is painted: a solid ping ring
/// covers every sample, the dashed no-signal ring only about half.
int ringCoverage(RenderedPixels pixels, Color background) {
  var covered = 0;
  for (var degrees = 0; degrees < 360; degrees += 10) {
    final radians = degrees * pi / 180;
    final point =
        _mapCenter +
        Offset(cos(radians) * _ringRadius, sin(radians) * _ringRadius);
    if (!pixels.matches(point, background)) {
      covered++;
    }
  }
  return covered;
}

void main() {
  testWidgets('paints a live aircraft amber', (tester) async {
    await pumpMiniMap(tester, at: position());

    expectAmberAircraft(await renderedPixels(tester, _mapKey));
  });

  testWidgets('grays the aircraft while there is no signal', (tester) async {
    await pumpMiniMap(tester, at: position(), state: FlightState.noSignal);

    expectGrayAircraft(await renderedPixels(tester, _mapKey));
  });

  testWidgets('rings a live aircraft solid and a silent one dashed', (
    tester,
  ) async {
    await pumpMiniMap(tester, at: position());
    final live = ringCoverage(
      await renderedPixels(tester, _mapKey),
      AppColors.white,
    );

    await pumpMiniMap(tester, at: position(), state: FlightState.noSignal);
    final noSignal = ringCoverage(
      await renderedPixels(tester, _mapKey),
      AppColors.white,
    );

    expect(live, greaterThan(noSignal));
    expect(noSignal, greaterThan(0));
  });

  testWidgets('follows a route-less flight when its position moves', (
    tester,
  ) async {
    await pumpMiniMap(tester, at: position());

    await pumpMiniMap(tester, at: position(latitude: 52, longitude: 20));
    await tester.pump();

    expectAmberAircraft(await renderedPixels(tester, _mapKey));
  });

  testWidgets('survives a trail point that sits on the latest position', (
    tester,
  ) async {
    await pumpMiniMap(tester, at: position(), trail: [trailPoint(48.5, -20)]);

    expect(tester.takeException(), isNull);
    expectAmberAircraft(await renderedPixels(tester, _mapKey));
  });

  testWidgets('draws the reduced style', (tester) async {
    await pumpMiniMap(tester, at: position(), withVectorTiles: true);

    expect(find.byType(VectorTileLayer), findsOneWidget);
  });

  testWidgets('follows the style the map tab settled on', (tester) async {
    final setting = await createTestMapStyleSetting();
    await setting.select(MapStyle.rasterOsm);

    await pumpMiniMap(
      tester,
      at: position(),
      withVectorTiles: true,
      mapStyleSetting: setting,
    );

    expect(find.byType(VectorTileLayer), findsNothing);

    await setting.select(MapStyle.reduced);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(VectorTileLayer), findsOneWidget);
  });
}
