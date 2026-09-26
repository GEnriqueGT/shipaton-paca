import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

final storePromosProvider =
    FutureProvider.autoDispose<List<Promotion>>((ref) async {
  if (!AppConfig.hasSupabase) {
    DemoStore.instance.seedIfNeeded();
    return List<Promotion>.from(DemoStore.instance.promotions);
  }
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return PromotionRepository(ref.watch(supabaseProvider)).listForStore(user.id);
});

class StorePromosScreen extends ConsumerStatefulWidget {
  const StorePromosScreen({super.key});

  @override
  ConsumerState<StorePromosScreen> createState() => _StorePromosScreenState();
}

class _StorePromosScreenState extends ConsumerState<StorePromosScreen> {
  final _title = TextEditingController();
  final _detail = TextEditingController();
  final _qty = TextEditingController(text: '3');
  PromoKind _kind = PromoKind.discount;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _snack('Escribe un título');
      return;
    }
    final detail = _detail.text.trim();
    int? qty;
    switch (_kind) {
      case PromoKind.discount:
        if (detail.isEmpty) {
          _snack('Escribe el descuento, por ejemplo 20% o Q15');
          return;
        }
      case PromoKind.bundle:
        qty = int.tryParse(_qty.text.trim());
        if (qty == null || qty < 2) {
          _snack('La cantidad tiene que ser 2 o más');
          return;
        }
        if (detail.isEmpty) {
          _snack('Escribe qué obtiene quien compra esas prendas');
          return;
        }
      case PromoKind.other:
        if (detail.isEmpty) {
          _snack('Describe la promoción');
          return;
        }
    }

    setState(() => _saving = true);
    try {
      if (!AppConfig.hasSupabase) {
        DemoStore.instance.promotions.insert(
          0,
          Promotion(
            id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
            storeId: 'demo-user',
            title: title,
            kind: _kind,
            bundleQty: qty,
            discountLabel: detail,
            storeName: DemoStore.instance.profile?.displayName,
          ),
        );
      } else {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        await PromotionRepository(ref.read(supabaseProvider)).create(
          storeId: user.id,
          title: title,
          kind: _kind,
          discountLabel: detail,
          bundleQty: qty,
        );
      }
      _title.clear();
      _detail.clear();
      ref.invalidate(storePromosProvider);
      if (mounted) _snack('Promoción creada');
    } catch (e) {
      if (mounted) _snack('No se pudo crear: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final gates = ref.watch(entitlementGatesProvider);
    ref.watch(demoPremiumTickProvider);
    final profile = AppConfig.hasSupabase
        ? ref.watch(profileProvider).valueOrNull
        : DemoStore.instance.profile;
    final canCreate = gates.canCreatePromos(profile?.role ?? UserRole.store);
    final promos = ref.watch(storePromosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canCreate) ...[
            const Text(
              'Crear promociones es de Tienda Pro: descuentos, compra de varias prendas u otro beneficio.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/paywall?role=store'),
              child: const Text('Activar Tienda Pro'),
            ),
          ] else ...[
            Text('Nueva promoción', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<PromoKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: PromoKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(kind.label),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (kind) {
                      if (kind == null) return;
                      setState(() => _kind = kind);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            if (_kind == PromoKind.bundle) ...[
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Cantidad de prendas'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _detail,
              decoration: InputDecoration(
                labelText: switch (_kind) {
                  PromoKind.discount => 'Descuento (20% o Q15)',
                  PromoKind.bundle => 'Qué obtiene',
                  PromoKind.other => 'Descripción',
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear promoción'),
            ),
          ],
          const SizedBox(height: 24),
          Text('Tus promociones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          promos.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e'),
            data: (items) {
              if (items.isEmpty) {
                return const Text('Todavía no has creado promociones.');
              }
              return Column(
                children: [
                  for (final promo in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_offer_outlined),
                      title: Text(promo.title),
                      subtitle: Text(
                        '${promo.kind.label}'
                        '${promo.benefit.isEmpty ? '' : ' · ${promo.benefit}'}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
