import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/guatemala.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

final exploreFiltersProvider =
    StateProvider<({String? department, String? category})>(
  (ref) => (department: null, category: null),
);

final explorePacasProvider = FutureProvider.autoDispose<List<Paca>>((ref) async {
  final filters = ref.watch(exploreFiltersProvider);
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    var list = List<Paca>.from(DemoStore.instance.pacas)
        .where((p) => p.status == PacaStatus.active)
        .toList();
    if (filters.department != null) {
      list = list
          .where((p) => p.storeDepartment == filters.department)
          .toList();
    }
    if (filters.category != null) {
      list = list.where((p) => p.category == filters.category).toList();
    }
    return list;
  }
  return PacaRepository(ref.watch(supabaseProvider)).listActive(
    department: filters.department,
    category: filters.category,
  );
});

class BuyerExploreScreen extends ConsumerWidget {
  const BuyerExploreScreen({super.key});

  static final _gtq = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacas = ref.watch(explorePacasProvider);
    final filters = ref.watch(exploreFiltersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar pacas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: filters.department,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Depto',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...guatemalaDepartments.map(
                        (d) => DropdownMenuItem(value: d, child: Text(d)),
                      ),
                    ],
                    onChanged: (v) {
                      ref.read(exploreFiltersProvider.notifier).state = (
                        department: v,
                        category: filters.category,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: filters.category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...pacaCategories.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (v) {
                      ref.read(exploreFiltersProvider.notifier).state = (
                        department: filters.department,
                        category: v,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pacas.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No hay pacas activas'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(explorePacasProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final paca = items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              context.push('/buyer/paca/${paca.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: paca.photoUrls.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: paca.photoUrls.first,
                                        fit: BoxFit.cover,
                                      )
                                    : const ColoredBox(
                                        color: Color(0xFFEEEEEE),
                                        child: Icon(Icons.checkroom, size: 48),
                                      ),
                              ),
                              ListTile(
                                title: Text(paca.title),
                                subtitle: Text(
                                  '${paca.storeName ?? 'Tienda'} · '
                                  '${paca.storeDepartment ?? 'GT'}',
                                ),
                                trailing: Text(
                                  _gtq.format(paca.priceGtq),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
