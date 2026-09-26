import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../share/post_templates.dart';
import '../share/share_service.dart';
import 'my_pacas_screen.dart';

class PublishScreen extends ConsumerStatefulWidget {
  const PublishScreen({super.key, required this.pacaId});

  final String pacaId;

  @override
  ConsumerState<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends ConsumerState<PublishScreen> {
  final _boundaryKey = GlobalKey();
  bool _wantBranded = false;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final pacasAsync = ref.watch(storePacasProvider);
    final gates = ref.watch(entitlementGatesProvider);
    ref.watch(demoPremiumTickProvider);
    final canBrand = gates.hasStorePremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa del post')),
      body: pacasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final paca = items.where((p) => p.id == widget.pacaId).firstOrNull;
          if (paca == null) {
            return const Center(child: Text('Paca no encontrada'));
          }

          final profile = AppConfig.hasSupabase
              ? ref.watch(profileProvider).valueOrNull
              : DemoStore.instance.profile;
          final useBranded = _wantBranded && canBrand;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Plantilla branded (Pro)'),
                subtitle: Text(
                  canBrand
                      ? 'Logo + color de marca'
                      : 'Requiere store_premium — toca para ver paywall',
                ),
                value: useBranded,
                onChanged: (v) {
                  if (!canBrand) {
                    context.push('/paywall?role=store');
                    return;
                  }
                  setState(() => _wantBranded = v);
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: useBranded
                      ? BrandedPostTemplate(
                          paca: paca,
                          brandColor: parseHexColor(
                            profile?.brandColor ?? '#1B5E20',
                          ),
                          storeName: profile?.displayName ?? paca.storeName,
                          logoUrl: profile?.logoUrl,
                        )
                      : PlainPostTemplate(
                          paca: paca,
                          storeName: profile?.displayName ?? paca.storeName,
                        ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sharing
                    ? null
                    : () => _share(
                          paca,
                          useBranded ? 'branded' : 'plain',
                          profile,
                        ),
                icon: const Icon(Icons.ios_share),
                label: Text(
                  _sharing
                      ? 'Compartiendo…'
                      : 'Compartir a WhatsApp / Facebook',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                useBranded
                    ? 'Plantilla branded lista para todas tus redes.'
                    : 'Free: fondo blanco. Upgrade Pro para branding.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _share(Paca paca, String template, Profile? profile) async {
    if (paca.photoUrls.isEmpty && AppConfig.hasSupabase) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una foto antes de publicar')),
      );
      return;
    }
    setState(() => _sharing = true);
    try {
      final copy =
          '${paca.title} — Q${paca.priceGtq.toStringAsFixed(0)}\n'
          '${profile?.displayName ?? 'Tienda'} · Guatemala\n'
          '${profile?.phoneWhatsapp != null ? 'WhatsApp: ${profile!.phoneWhatsapp}' : ''}';
      await captureAndShare(
        boundaryKey: _boundaryKey,
        text: copy,
        fileName: 'paca_${paca.id}.png',
      );
      if (AppConfig.hasSupabase) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          await PacaRepository(ref.read(supabaseProvider)).logShare(
            storeId: user.id,
            pacaId: paca.id,
            template: template,
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post $template listo para tus redes')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
