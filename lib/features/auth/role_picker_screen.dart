import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

class RolePickerScreen extends ConsumerStatefulWidget {
  const RolePickerScreen({super.key});

  @override
  ConsumerState<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends ConsumerState<RolePickerScreen> {
  bool _loading = false;

  Future<void> _pick(UserRole role) async {
    setState(() => _loading = true);
    try {
      if (!AppConfig.hasSupabase) {
        DemoStore.instance.seedIfNeeded();
        DemoStore.instance.profile = Profile(
          id: 'demo-user',
          role: role,
          displayName: role == UserRole.store ? 'Mi Tienda Demo' : 'Comprador Demo',
          department: 'Guatemala',
          phoneWhatsapp: '50255551234',
        );
        if (!mounted) return;
        context.go(role == UserRole.store ? '/store' : '/buyer');
        return;
      }

      final user = ref.read(currentUserProvider);
      if (user == null) {
        context.go('/auth');
        return;
      }
      final repo = ProfileRepository(ref.read(supabaseProvider));
      final existing = await repo.fetch(user.id);
      final updated = (existing ?? Profile(id: user.id)).copyWith(
        role: role,
        displayName: existing?.displayName ??
            (role == UserRole.store ? 'Mi tienda' : 'Comprador'),
      );
      await repo.update(updated);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      context.go(role == UserRole.store ? '/store' : '/buyer');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el rol: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo vas a usar Paca GT?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige tu rol. Puedes cambiarlo después en Perfil.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.storefront,
              title: 'Soy tienda',
              subtitle:
                  'Publica pacas y genera posts para WhatsApp / Facebook',
              onTap: _loading ? null : () => _pick(UserRole.store),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Soy comprador',
              subtitle: 'Explora pacas en Guatemala y ve promos exclusivas',
              onTap: _loading ? null : () => _pick(UserRole.buyer),
            ),
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (!AppConfig.hasSupabase) ...[
              const Spacer(),
              Text(
                'Modo demo (sin SUPABASE_URL). Los datos viven en memoria.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
