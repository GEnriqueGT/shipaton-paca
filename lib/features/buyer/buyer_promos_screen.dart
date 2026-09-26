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
    final canRedeem = gates.hasBuyerPremium;
    final promos = ref.watch(promotionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      body: promos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No hay promociones por ahora'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final promo = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${promo.storeName ?? 'Tienda'} · ${promo.kind.label}',
                      ),
                      const SizedBox(height: 12),
                      if (canRedeem)
                        Text(
                          promo.benefit.isEmpty
                              ? 'Promoción activa'
                              : promo.benefit,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      else ...[
                        const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Suscríbete para obtener esta promoción',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton(
                            onPressed: () =>
                                context.push('/paywall?role=buyer'),
                            child: const Text('Ver con Comprador Pro'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
