import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/providers/app_providers.dart';

class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gates = ref.watch(entitlementGatesProvider);
    ref.watch(demoPremiumTickProvider);
    final demo = !AppConfig.hasRevenueCat;
    final active = gates.hasBuyerPremium;
    final profile = AppConfig.hasSupabase
        ? ref.watch(profileProvider).valueOrNull
        : DemoStore.instance.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(profile?.displayName ?? 'Comprador'),
            subtitle: Text(profile?.department ?? 'Guatemala'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(active ? Icons.verified : Icons.lock_outline),
            title: Text(active ? 'Comprador Pro activo' : 'Plan free'),
            subtitle: const Text('Entitlement: buyer_premium'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/paywall?role=buyer'),
          ),
          if (demo)
            SwitchListTile(
              title: const Text('Demo: simular buyer_premium'),
              value: DemoStore.instance.buyerPremium,
              onChanged: (v) {
                DemoStore.instance.buyerPremium = v;
                ref.read(demoPremiumTickProvider.notifier).state++;
              },
            ),
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('Cambiar rol'),
            onTap: () async {
              if (AppConfig.hasSupabase) {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  await ref.read(supabaseProvider).from('profiles').update({
                    'role': null,
                  }).eq('id', user.id);
                  ref.invalidate(profileProvider);
                }
              } else {
                DemoStore.instance.profile = null;
              }
              if (context.mounted) context.go('/role');
            },
          ),
          if (AppConfig.hasSupabase)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                await ref.read(customerInfoProvider.notifier).logOut();
                await ref.read(supabaseProvider).auth.signOut();
                if (context.mounted) context.go('/auth');
              },
            ),
        ],
      ),
    );
  }
}
