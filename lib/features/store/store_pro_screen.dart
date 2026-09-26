import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/providers/app_providers.dart';

class StoreProScreen extends ConsumerWidget {
  const StoreProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gates = ref.watch(entitlementGatesProvider);
    ref.watch(demoPremiumTickProvider);
    final demo = !AppConfig.hasRevenueCat;
    final active = gates.hasStorePremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Tienda Pro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            active ? Icons.verified : Icons.lock_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            active ? 'Tienes store_premium' : 'Plan free',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Pro desbloquea plantillas branded (logo, color, tipografía) '
            'para publicar en WhatsApp y Facebook sin diseñar a mano.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push('/paywall?role=store'),
            child: Text(active ? 'Ver ofertas' : 'Mejorar a Pro'),
          ),
          if (demo) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Demo: simular store_premium'),
              value: DemoStore.instance.storePremium,
              onChanged: (v) {
                DemoStore.instance.storePremium = v;
                ref.read(demoPremiumTickProvider.notifier).state++;
              },
            ),
          ],
        ],
      ),
    );
  }
}
