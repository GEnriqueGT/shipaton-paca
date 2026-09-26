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
import '../share/save_ad.dart';

final storePacasProvider = FutureProvider.autoDispose<List<Paca>>((ref) async {
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    return List<Paca>.from(DemoStore.instance.pacas);
  }
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return PacaRepository(ref.watch(supabaseProvider)).listForStore(user.id);
});

class MyPacasScreen extends ConsumerWidget {
  const MyPacasScreen({super.key});

  static final _gtq = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacas = ref.watch(storePacasProvider);
    final profile = AppConfig.hasSupabase
        ? ref.watch(profileProvider).valueOrNull
        : DemoStore.instance.profile;
    final gates = ref.watch(entitlementGatesProvider);
    ref.watch(demoPremiumTickProvider);
    final brand = parseHexColor(profile?.brandColor ?? '#1B5E20');

    return Scaffold(
      body: pacas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(storePacasProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _StoreHeader(profile: profile, brand: brand),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/store/promos'),
                    icon: const Icon(Icons.local_offer_outlined),
                    label: const Text('Promociones'),
                  ),
                ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aún no tienes productos. Crea el primero.'),
                  )
                else
                  ...items.map(
                    (paca) => _ProductCard(
                      paca: paca,
                      price: _gtq.format(paca.priceGtq),
                      canRegenerate:
                          gates.hasStorePremium && paca.photoUrls.isNotEmpty,
                      onEdit: () => context.push('/store/paca/${paca.id}'),
                      onShare: () => context.push('/store/publish/${paca.id}'),
                      onTogglePublish: () => _togglePublish(ref, paca),
                      onRegenerate: () => _regenerate(ref, paca, profile),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _togglePublish(WidgetRef ref, Paca paca) async {
    final next = paca.status == PacaStatus.active
        ? PacaStatus.draft
        : PacaStatus.active;
    if (!AppConfig.hasSupabase) {
      final index = DemoStore.instance.pacas.indexWhere((p) => p.id == paca.id);
      if (index != -1) {
        final current = DemoStore.instance.pacas[index];
        DemoStore.instance.pacas[index] = Paca(
          id: current.id,
          storeId: current.storeId,
          title: current.title,
          description: current.description,
          priceGtq: current.priceGtq,
          category: current.category,
          sizeMix: current.sizeMix,
          photoUrls: current.photoUrls,
          adUrl: current.adUrl,
          status: next,
          storeName: current.storeName,
          storePhone: current.storePhone,
          storeDepartment: current.storeDepartment,
        );
      }
      ref.invalidate(storePacasProvider);
      return;
    }
    await PacaRepository(ref.read(supabaseProvider)).setStatus(paca.id, next);
    ref.invalidate(storePacasProvider);
  }

  Future<void> _regenerate(WidgetRef ref, Paca paca, Profile? profile) async {
    await generateAndStoreAd(ref, paca: paca, profile: profile);
    ref.invalidate(storePacasProvider);
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.profile, required this.brand});

  final Profile? profile;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName?.trim().isNotEmpty == true
        ? profile!.displayName!
        : 'Mi tienda';
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
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Productos',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
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
                  name.substring(0, 1).toUpperCase(),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.paca,
    required this.price,
    required this.canRegenerate,
    required this.onEdit,
    required this.onShare,
    required this.onTogglePublish,
    required this.onRegenerate,
  });

  final Paca paca;
  final String price;
  final bool canRegenerate;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onTogglePublish;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final published = paca.status == PacaStatus.active;
    final image = paca.heroUrl;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              published ? 'Publicado en la tienda' : 'Solo en borrador',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Wrap(
              spacing: 4,
              children: [
                TextButton(onPressed: onEdit, child: const Text('Editar')),
                TextButton(
                  onPressed: onShare,
                  child: const Text('Compartir en redes'),
                ),
                TextButton(
                  onPressed: onTogglePublish,
                  child: Text(published ? 'Retirar' : 'Publicar'),
                ),
                if (canRegenerate)
                  TextButton(
                    onPressed: onRegenerate,
                    child: const Text('Regenerar'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
