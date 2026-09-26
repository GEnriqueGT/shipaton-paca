import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import 'buyer_explore_screen.dart';

class PacaDetailScreen extends ConsumerWidget {
  const PacaDetailScreen({super.key, required this.pacaId});

  final String pacaId;

  static final _gtq = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacas = ref.watch(explorePacasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: pacas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final paca = items.where((p) => p.id == pacaId).firstOrNull;
          if (paca == null) {
            // Try store list / demo all
            final fallback = !AppConfig.hasSupabase
                ? DemoStore.instance.pacas
                    .where((p) => p.id == pacaId)
                    .firstOrNull
                : null;
            if (fallback == null) {
              return const Center(child: Text('Paca no encontrada'));
            }
            return _body(context, fallback);
          }
          return _body(context, paca);
        },
      ),
    );
  }

  Widget _body(BuildContext context, Paca paca) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: paca.photoUrls.isNotEmpty
              ? Image.network(paca.photoUrls.first, fit: BoxFit.cover)
              : const ColoredBox(
                  color: Color(0xFFEEEEEE),
                  child: Icon(Icons.checkroom, size: 72),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          paca.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _gtq.format(paca.priceGtq),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (paca.description != null) ...[
          const SizedBox(height: 12),
          Text(paca.description!),
        ],
        const SizedBox(height: 8),
        Text(
          '${paca.storeName ?? 'Tienda'} · ${paca.storeDepartment ?? 'Guatemala'}',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: paca.storePhone == null || paca.storePhone!.isEmpty
              ? null
              : () => _openWhatsApp(paca.storePhone!, paca.title),
          icon: const Icon(Icons.chat),
          label: const Text('Contactar por WhatsApp'),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    final text = Uri.encodeComponent('Hola, me interesa la paca: $title');
    final uri = Uri.parse('https://wa.me/$cleaned?text=$text');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
