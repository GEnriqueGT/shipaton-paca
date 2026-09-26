import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'product_cutout.dart';

/// Product photo with the light backdrop removed when possible.
class ProductPhoto extends StatefulWidget {
  const ProductPhoto({super.key, required this.url});

  final String url;

  @override
  State<ProductPhoto> createState() => _ProductPhotoState();
}

class _ProductPhotoState extends State<ProductPhoto> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProductPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final raw = await _download(widget.url);
      final cutout = knockOutLightBackground(raw);
      if (!mounted) return;
      setState(() => _bytes = cutout ?? raw);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (_failed) {
      return CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.contain,
        errorWidget: (_, _, _) => const Icon(
          Icons.image_not_supported,
          color: Colors.white,
          size: 64,
        ),
      );
    }
    if (bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
  }
}

/// Tilts [child] in perspective. Drag to change the angle.
class ProductStage extends StatefulWidget {
  const ProductStage({super.key, required this.child});

  final Widget child;

  @override
  State<ProductStage> createState() => _ProductStageState();
}

class _ProductStageState extends State<ProductStage> {
  double _yaw = -0.18;
  double _pitch = 0.06;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          _ClaimingPanRecognizer:
              GestureRecognizerFactoryWithHandlers<_ClaimingPanRecognizer>(
            () => _ClaimingPanRecognizer(),
            (_ClaimingPanRecognizer instance) {
              instance.onUpdate = (details) {
                setState(() {
                  _yaw = (_yaw + details.delta.dx * 0.008).clamp(-0.65, 0.65);
                  _pitch = (_pitch - details.delta.dy * 0.006).clamp(-0.28, 0.4);
                });
              };
            },
          ),
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(_yaw * 28, 96),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 8),
                child: Container(
                  width: 170,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0008)
                ..rotateX(_pitch)
                ..rotateY(_yaw),
              child: SizedBox(width: 250, height: 250, child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClaimingPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

Future<Uint8List> _download(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}');
    }
    return await consolidateHttpClientResponseBytes(response);
  } finally {
    client.close();
  }
}
