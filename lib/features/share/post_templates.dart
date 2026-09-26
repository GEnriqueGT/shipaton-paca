import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import 'product_stage.dart';

final _gtq = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

class PlainPostTemplate extends StatelessWidget {
  const PlainPostTemplate({
    super.key,
    required this.paca,
    this.storeName,
  });

  final Paca paca;
  final String? storeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (paca.photoUrls.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: paca.photoUrls.first,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const ColoredBox(
                  color: Color(0xFFEEEEEE),
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            )
          else
            const AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(
                color: Color(0xFFEEEEEE),
                child: Center(child: Icon(Icons.checkroom, size: 64)),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            paca.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _gtq.format(paca.priceGtq),
            style: const TextStyle(fontSize: 20, color: Colors.black87),
          ),
          if (paca.description != null && paca.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              paca.description!,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            storeName ?? 'Tienda',
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class BrandedPostTemplate extends StatelessWidget {
  const BrandedPostTemplate({
    super.key,
    required this.paca,
    required this.brandColor,
    this.storeName,
    this.logoUrl,
    this.backgroundBytes,
    this.generatedAdBytes,
    this.showWatermark = false,
  });

  final Paca paca;
  final Color brandColor;
  final String? storeName;
  final String? logoUrl;
  final Uint8List? backgroundBytes;
  final Uint8List? generatedAdBytes;
  final bool showWatermark;

  @override
  Widget build(BuildContext context) {
    final name = (storeName == null || storeName!.trim().isEmpty)
        ? 'Mi tienda'
        : storeName!.trim();

    return SizedBox(
      width: 360,
      child: Stack(
        children: [
          Positioned.fill(child: _backdrop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (generatedAdBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      generatedAdBytes!,
                      width: 328,
                      height: 320,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  ProductStage(child: _product()),
                const SizedBox(height: 4),
                _footer(name),
              ],
            ),
          ),
          if (showWatermark)
            const Positioned.fill(
              child: IgnorePointer(child: _PreviewWatermark()),
            ),
        ],
      ),
    );
  }

  Widget _footer(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _logo(name),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            paca.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _gtq.format(paca.priceGtq),
            style: TextStyle(
              color: brandColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _backdrop() {
    final bytes = backgroundBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    final deep = Color.lerp(brandColor, Colors.black, 0.18)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 0.95,
          colors: [brandColor, deep],
        ),
      ),
    );
  }

  Widget _logo(String name) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _product() {
    if (paca.photoUrls.isEmpty) {
      return const Icon(Icons.checkroom, size: 96, color: Colors.white);
    }
    return ProductPhoto(url: paca.photoUrls.first);
  }
}

class _PreviewWatermark extends StatelessWidget {
  const _PreviewWatermark();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: const Color(0x22000000),
        child: FittedBox(
          fit: BoxFit.cover,
          child: Transform.rotate(
            angle: -0.5,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WatermarkLine(),
                SizedBox(height: 48),
                _WatermarkLine(),
                SizedBox(height: 48),
                _WatermarkLine(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatermarkLine extends StatelessWidget {
  const _WatermarkLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      'VISTA PREVIA',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.42),
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 4,
      ),
    );
  }
}

Color parseHexColor(String hex, {Color fallback = const Color(0xFF1B5E20)}) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
