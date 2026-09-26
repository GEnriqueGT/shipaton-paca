import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pacas'),
        actions: [
          IconButton(
            tooltip: 'Cambiar rol',
            onPressed: () async {
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
            icon: const Icon(Icons.switch_account),
          ),
        ],
      ),
      body: pacas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Aún no tienes pacas. Crea la primera.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(storePacasProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final paca = items[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: paca.photoUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: paca.photoUrls.first,
                              fit: BoxFit.cover,
                            )
                          : const ColoredBox(
                              color: Color(0xFFEEEEEE),
                              child: Icon(Icons.checkroom),
                            ),
                    ),
                  ),
                  title: Text(paca.title),
                  subtitle: Text(
                    '${_gtq.format(paca.priceGtq)} · ${paca.status.dbValue}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        context.push('/store/paca/${paca.id}');
                      } else if (v == 'publish') {
                        context.push('/store/publish/${paca.id}');
                      } else if (v == 'delete') {
                        await _delete(ref, paca.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'publish', child: Text('Publicar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                  onTap: () => context.push('/store/paca/${paca.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(WidgetRef ref, String id) async {
    if (!AppConfig.hasSupabase) {
      DemoStore.instance.pacas.removeWhere((p) => p.id == id);
      ref.invalidate(storePacasProvider);
      return;
    }
    await PacaRepository(ref.read(supabaseProvider)).delete(id);
    ref.invalidate(storePacasProvider);
  }
}
