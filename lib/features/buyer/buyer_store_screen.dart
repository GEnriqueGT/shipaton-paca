import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../share/post_templates.dart';

final storeProductsProvider =
    FutureProvider.autoDispose.family<List<Paca>, String>((ref, storeId) async {
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    return DemoStore.instance.pacas
        .where((paca) => paca.storeId == storeId && paca.status == PacaStatus.active)
        .toList();
  }
  return PacaRepository(ref.watch(supabaseProvider)).listPublished(storeId);
});

final storeProfileProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, storeId) async {
  if (!AppConfig.hasSupabase) {
    final profile = DemoStore.instance.profile;
    if (profile?.id == storeId) return profile;
    if (storeId == 'demo-user') {
      return profile ??
          const Profile(
            id: 'demo-user',
            role: UserRole.store,
            displayName: 'Pacas Zona 1',
            department: 'Guatemala',
          );
    }
    return null;
  }
  return ProfileRepository(ref.watch(supabaseProvider)).fetch(storeId);
});

class BuyerStoreScreen extends ConsumerWidget {
  const BuyerStoreScreen({super.key, required this.storeId});

  final String storeId;

  static final _gtq = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(storeProfileProvider(storeId));
    final products = ref.watch(storeProductsProvider(storeId));
    final store = profile.valueOrNull;
    final brand = parseHexColor(store?.brandColor ?? '#1B5E20');
    final name = store?.displayName?.trim().isNotEmpty == true
        ? store!.displayName!
        : 'Tienda';

    return Scaffold(
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(name),
                  background: store?.coverUrl != null && store!.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: store.coverUrl!,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(color: brand),
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Esta tienda no tiene productos publicados')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final paca = items[i];
                      final image = paca.heroUrl;
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push('/buyer/paca/${paca.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 180,
                                child: image == null
                                    ? const ColoredBox(
                                        color: Color(0xFFEEEEEE),
                                        child: Icon(Icons.checkroom, size: 48),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: image,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              ListTile(
                                title: Text(paca.title),
                                trailing: Text(
                                  _gtq.format(paca.priceGtq),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
