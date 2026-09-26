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

final buyerStorePromosProvider =
    FutureProvider.autoDispose.family<List<Promotion>, String>((ref, storeId) async {
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    return DemoStore.instance.promotions
        .where((promo) => promo.storeId == storeId)
        .toList();
  }
  return PromotionRepository(ref.watch(supabaseProvider)).listForStore(storeId);
});

class BuyerStoreScreen extends ConsumerWidget {
  const BuyerStoreScreen({super.key, required this.storeId});

  final String storeId;

  static final _gtq = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(storeProfileProvider(storeId));
    final products = ref.watch(storeProductsProvider(storeId));
    final promos = ref.watch(buyerStorePromosProvider(storeId));
    final gates = ref.watch(entitlementGatesProvider);
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
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _BuyerStoreHeader(
                profile: store,
                brand: brand,
                name: name,
                onBack: () => context.pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  'Promociones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              promos.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$e'),
                ),
                data: (offers) {
                  if (offers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text('Esta tienda no tiene promociones'),
                    );
                  }
                  return Column(
                    children: [
                      for (final promo in offers)
                        _StorePromoTile(
                          promo: promo,
                          canRedeem: gates.hasBuyerPremium,
                          onUnlock: () => context.push('/paywall?role=buyer'),
                        ),
                    ],
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Productos',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Esta tienda no tiene productos publicados'),
                )
              else
                for (final paca in items)
                  _BuyerProductCard(
                    paca: paca,
                    price: _gtq.format(paca.priceGtq),
                    onTap: () => context.push('/buyer/paca/${paca.id}'),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _BuyerStoreHeader extends StatelessWidget {
  const _BuyerStoreHeader({
    required this.profile,
    required this.brand,
    required this.name,
    required this.onBack,
  });

  final Profile? profile;
  final Color brand;
  final String name;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 168,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _cover(profile?.coverUrl, brand)),
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Positioned(
                left: 20,
                bottom: -28,
                child: _logo(profile?.logoUrl, name, brand),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        if (profile?.department != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              profile!.department!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _cover(String? url, Color brand) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand, Color.lerp(brand, Colors.black, 0.25)!],
        ),
      ),
    );
  }

  Widget _logo(String? url, String name, Color brand) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          : ColoredBox(
              color: brand,
              child: Center(
                child: Text(
                  name.isEmpty ? 'T' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}

class _StorePromoTile extends StatelessWidget {
  const _StorePromoTile({
    required this.promo,
    required this.canRedeem,
    required this.onUnlock,
  });

  final Promotion promo;
  final bool canRedeem;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(promo.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(promo.kind.label),
            const SizedBox(height: 12),
            if (canRedeem)
              Text(
                promo.benefit.isEmpty ? 'Promoción activa' : promo.benefit,
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Obtener con Comprador Pro'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuyerProductCard extends StatelessWidget {
  const _BuyerProductCard({
    required this.paca,
    required this.price,
    required this.onTap,
  });

  final Paca paca;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = paca.heroUrl;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      paca.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
