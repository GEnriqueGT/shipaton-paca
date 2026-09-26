import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';

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
                errorWidget: (_, __, ___) => const ColoredBox(
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
  });

  final Paca paca;
  final Color brandColor;
  final String? storeName;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandColor,
            Color.lerp(brandColor, Colors.black, 0.35)!,
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (logoUrl != null && logoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: logoUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (storeName ?? 'P').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  storeName ?? 'Mi tienda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: paca.photoUrls.isNotEmpty
                ? AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: paca.photoUrls.first,
                      fit: BoxFit.cover,
                    ),
                  )
                : const AspectRatio(
                    aspectRatio: 1,
                    child: ColoredBox(
                      color: Colors.white24,
                      child: Icon(Icons.checkroom, size: 64, color: Colors.white),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            paca.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _gtq.format(paca.priceGtq),
              style: TextStyle(
                color: brandColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          if (paca.category != null) ...[
            const SizedBox(height: 10),
            Text(
              '#${paca.category} · Guatemala',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
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
