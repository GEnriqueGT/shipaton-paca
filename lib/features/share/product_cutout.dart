import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Removes an edge-connected near-white backdrop from a product photo.
///
/// Returns PNG bytes with transparency, or null when the photo does not have
/// a clear light background (so the caller keeps the original image).
Uint8List? knockOutLightBackground(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final resized = decoded.width > 900
      ? img.copyResize(decoded, width: 900)
      : decoded;
  final image = resized.convert(numChannels: 4);
  final width = image.width;
  final height = image.height;
  final visited = List<bool>.filled(width * height, false);
  final queue = <int>[];

  void tryPush(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final index = y * width + x;
    if (visited[index]) return;
    visited[index] = true;
    if (!_isNearWhite(image.getPixel(x, y))) return;
    queue.add(index);
  }

  for (var x = 0; x < width; x++) {
    tryPush(x, 0);
    tryPush(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    tryPush(0, y);
    tryPush(width - 1, y);
  }

  var removed = 0;
  var head = 0;
  while (head < queue.length) {
    final index = queue[head++];
    final x = index % width;
    final y = index ~/ width;
    image.setPixelRgba(x, y, 0, 0, 0, 0);
    removed++;
    tryPush(x + 1, y);
    tryPush(x - 1, y);
    tryPush(x, y + 1);
    tryPush(x, y - 1);
  }

  final ratio = removed / (width * height);
  if (ratio < 0.08 || ratio > 0.85) return null;

  return Uint8List.fromList(img.encodePng(image));
}

bool _isNearWhite(img.Pixel pixel) {
  final r = pixel.r.toInt();
  final g = pixel.g.toInt();
  final b = pixel.b.toInt();
  final minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
  final maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
  return minChannel >= 242 && (maxChannel - minChannel) <= 18;
}
