import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

final promotionsProvider =
    FutureProvider.autoDispose<List<Promotion>>((ref) async {
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    return List<Promotion>.from(DemoStore.instance.promotions);
  }
  return PromotionRepository(ref.watch(supabaseProvider)).listAll();
});

class BuyerPromosScreen extends ConsumerWidget {
  const BuyerPromosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gates = ref.watch(entitlementGatesProvider);
    ref.watch(demoPremiumTickProvider);
    final canView = gates.hasBuyerPremium;
    final promos = ref.watch(promotionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      body: !canView
          ? _LockedPromos(onUpgrade: () => context.push('/paywall?role=buyer'))
          : promos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                final exclusive =
                    items.where((p) => p.premiumOnly).toList();
                if (exclusive.isEmpty) {
                  return const Center(
                    child: Text('No hay promos exclusivas por ahora'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: exclusive.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final promo = exclusive[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      leading: const Icon(Icons.local_offer),
                      title: Text(promo.title),
                      subtitle: Text(
                        '${promo.storeName ?? 'Tienda'}'
                        '${promo.discountLabel != null ? ' · ${promo.discountLabel}' : ''}',
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _LockedPromos extends StatelessWidget {
  const _LockedPromos({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Promos exclusivas de ropa',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Con Comprador Pro ves descuentos y ofertas premium_only '
            'de tiendas de pacas en Guatemala.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onUpgrade,
            child: const Text('Desbloquear con buyer_premium'),
          ),
        ],
      ),
    );
  }
}
