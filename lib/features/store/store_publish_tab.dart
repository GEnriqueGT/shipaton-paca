import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'my_pacas_screen.dart';

class StorePublishTab extends ConsumerWidget {
  const StorePublishTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacas = ref.watch(storePacasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar en redes')),
      body: pacas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final active = items.where((p) => p.status.name != 'sold').toList();
          if (active.isEmpty) {
            return const Center(
              child: Text('Crea una paca primero para generar el post.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            itemBuilder: (context, i) {
              final paca = active[i];
              return ListTile(
                title: Text(paca.title),
                subtitle: const Text('Generar post y compartir'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/store/publish/${paca.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
