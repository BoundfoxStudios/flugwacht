import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a repaint boundary actually painted, so a test can assert on the
/// pixels a user would see instead of on the widget tree that produced them.
class RenderedPixels {
  const RenderedPixels(this._pixels, this._width);

  final ByteData _pixels;
  final int _width;

  Color at(Offset point) {
    final offset = (point.dy.toInt() * _width + point.dx.toInt()) * 4;
    return Color.fromARGB(
      _pixels.getUint8(offset + 3),
      _pixels.getUint8(offset),
      _pixels.getUint8(offset + 1),
      _pixels.getUint8(offset + 2),
    );
  }

  bool matches(Offset point, Color color) =>
      at(point).toARGB32() == color.toARGB32();
}

Future<RenderedPixels> renderedPixels(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final pixels = (await image.toByteData())!;
    return RenderedPixels(pixels, image.width);
  }))!;
}
