import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/guatemala.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../share/post_templates.dart';

final exploreFiltersProvider = StateProvider<String?>((ref) => null);

final exploreStoresProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final department = ref.watch(exploreFiltersProvider);
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    final profile = DemoStore.instance.profile ??
        const Profile(
          id: 'demo-user',
          role: UserRole.store,
          displayName: 'Pacas Zona 1',
          department: 'Guatemala',
        );
    if (department != null && profile.department != department) return [];
    return [profile];
  }
  final stores =
      await ProfileRepository(ref.watch(supabaseProvider)).listStores();
  if (department == null || department.isEmpty) return stores;
  return stores.where((store) => store.department == department).toList();
});

class BuyerExploreScreen extends ConsumerWidget {
  const BuyerExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(exploreStoresProvider);
    final department = ref.watch(exploreFiltersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tiendas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DropdownButtonFormField<String?>(
              initialValue: department,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Departamento',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...guatemalaDepartments.map(
                  (d) => DropdownMenuItem(value: d, child: Text(d)),
                ),
              ],
              onChanged: (v) {
                ref.read(exploreFiltersProvider.notifier).state = v;
              },
            ),
          ),
          Expanded(
            child: stores.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Todavía no hay tiendas publicadas'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(exploreStoresProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final store = items[i];
                      return _StoreCard(store: store);
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});

  final Profile store;

  @override
  Widget build(BuildContext context) {
    final brand = parseHexColor(store.brandColor);
    final name = store.displayName?.trim().isNotEmpty == true
        ? store.displayName!
        : 'Tienda';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/buyer/store/${store.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 140,
              child: store.coverUrl != null && store.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: store.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(color: brand),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: brand,
                backgroundImage:
                    store.logoUrl != null && store.logoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(store.logoUrl!)
                        : null,
                child: store.logoUrl == null || store.logoUrl!.isEmpty
                    ? Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(name),
              subtitle: Text(store.department ?? 'Guatemala'),
            ),
          ],
        ),
      ),
    );
  }
}
