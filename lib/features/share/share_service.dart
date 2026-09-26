import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<XFile?> captureAndShare({
  required GlobalKey boundaryKey,
  required String text,
  String fileName = 'paca_post.png',
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final image = await boundary.toImage(pixelRatio: 3);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;

  final bytes = byteData.buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);

  final xFile = XFile(file.path, mimeType: 'image/png');
  await SharePlus.instance.share(
    ShareParams(
      files: [xFile],
      text: text,
    ),
  );
  return xFile;
}
