import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_generator.dart';

/// Generates the studio ad and stores it on the product.
/// Returns the public URL, or null when generation is skipped or fails.
Future<String?> generateAndStoreAd(
  WidgetRef ref, {
  required Paca paca,
  required Profile? profile,
}) async {
  final source = paca.photoUrls.isNotEmpty ? paca.photoUrls.first : null;
  if (source == null || source.isEmpty) return null;
  if (!AppConfig.hasOpenRouter || !AppConfig.hasSupabase) return null;

  final details = [
    paca.description,
    paca.category,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' · ');

  final photo = await fetchImageBytes(source);
  final bytes = await generateStudioAd(
    photo: photo,
    brandHex: profile?.brandColor ?? '#1B5E20',
    storeName: profile?.displayName ?? paca.storeName ?? 'Tienda',
    title: paca.title,
    priceGtq: paca.priceGtq,
    sizes: paca.sizeMix ?? '',
    details: details,
  );

  final repo = PacaRepository(ref.read(supabaseProvider));
  final url = await repo.uploadAdBytes(paca.storeId, bytes);
  await repo.setAdUrl(paca.id, url);
  return url;
}
