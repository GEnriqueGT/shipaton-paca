import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shipaton_tienda/features/share/product_cutout.dart';

void main() {
  test('removes an edge-connected white background', () {
    final canvas = img.Image(width: 80, height: 80, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
    img.fillRect(
      canvas,
      x1: 25,
      y1: 20,
      x2: 55,
      y2: 60,
      color: img.ColorRgba8(40, 40, 40, 255),
    );
    final png = Uint8List.fromList(img.encodePng(canvas));

    final out = knockOutLightBackground(png);

    expect(out, isNotNull);
    final decoded = img.decodePng(out!)!;
    expect(decoded.getPixel(0, 0).a, 0);
    expect(decoded.getPixel(40, 40).a, greaterThan(200));
  });

  test('keeps the photo when the background is not light', () {
    final canvas = img.Image(width: 40, height: 40, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(20, 80, 40, 255));
    final png = Uint8List.fromList(img.encodePng(canvas));

    expect(knockOutLightBackground(png), isNull);
  });
}
