import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../share/ad_generator.dart';
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
  bool _generating = false;
  Uint8List? _backgroundBytes;
  Uint8List? _generatedAd;
  String? _generatedFor;

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
          final useBranded = _wantBranded;
          final generatedAd =
              _generatedFor == paca.id ? _generatedAd : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Plantilla branded (Pro)'),
                subtitle: Text(
                  canBrand
                      ? 'Logo, color de marca y prenda en ángulo'
                      : 'Vista previa. Compartir Pro requiere store_premium',
                ),
                value: useBranded,
                onChanged: (v) {
                  setState(() => _wantBranded = v);
                  if (v &&
                      AppConfig.hasOpenRouter &&
                      !_generating &&
                      generatedAd == null) {
                    _generateAd(
                      paca,
                      profile?.brandColor ?? '#1B5E20',
                    );
                  }
                },
              ),
              if (useBranded) ...[
                const SizedBox(height: 4),
                if (AppConfig.hasOpenRouter)
                  OutlinedButton.icon(
                    onPressed: _generating
                        ? null
                        : () => _generateAd(
                              paca,
                              profile?.brandColor ?? '#1B5E20',
                            ),
                    icon: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _generating
                          ? 'Generando imagen'
                          : generatedAd == null
                              ? 'Generar publicidad'
                              : 'Generar de nuevo',
                    ),
                  )
                else
                  Text(
                    'Agrega OPENROUTER_API_KEY en el .env para generar la publicidad.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickBackground,
                        icon: const Icon(Icons.wallpaper),
                        label: Text(
                          _backgroundBytes == null ? 'Subir fondo' : 'Cambiar fondo',
                        ),
                      ),
                    ),
                    if (_backgroundBytes != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Quitar fondo',
                        onPressed: () => setState(() => _backgroundBytes = null),
                        icon: const Icon(Icons.hide_image_outlined),
                      ),
                    ],
                  ],
                ),
                if (generatedAd == null && !_generating) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Arrastra la prenda para inclinarla.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Center(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: useBranded && _generating
                      ? const _GeneratingAdCard()
                      : useBranded
                      ? BrandedPostTemplate(
                          paca: paca,
                          brandColor: parseHexColor(
                            profile?.brandColor ?? '#1B5E20',
                          ),
                          storeName: profile?.displayName ?? paca.storeName,
                          logoUrl: profile?.logoUrl,
                          backgroundBytes: _backgroundBytes,
                          generatedAdBytes: generatedAd,
                          showWatermark: !canBrand,
                        )
                      : PlainPostTemplate(
                          paca: paca,
                          storeName: profile?.displayName ?? paca.storeName,
                        ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sharing || _generating
                    ? null
                    : () {
                        if (useBranded && !canBrand) {
                          context.push('/paywall?role=store');
                          return;
                        }
                        _share(
                          paca,
                          useBranded ? 'branded' : 'plain',
                          profile,
                        );
                      },
                icon: const Icon(Icons.ios_share),
                label: Text(
                  _sharing
                      ? 'Compartiendo…'
                      : useBranded && !canBrand
                          ? 'Compartir Pro'
                          : 'Compartir a WhatsApp / Facebook',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                useBranded
                    ? (canBrand
                        ? 'Plantilla branded lista para todas tus redes.'
                        : 'Así se ve con Pro. El plan free comparte fondo blanco.')
                    : 'Free: fondo blanco. Activa Pro para ver el branding.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateAd(Paca paca, String brandHex) async {
    if (paca.photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una foto antes de generar')),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      final photo = await fetchImageBytes(paca.photoUrls.first);
      final ad = await generateStudioAd(photo: photo, brandHex: brandHex);
      if (!mounted) return;
      setState(() {
        _generatedAd = ad;
        _generatedFor = paca.id;
      });
    } on AdGenerationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar la publicidad. Intenta de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _pickBackground() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _backgroundBytes = bytes);
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

class _GeneratingAdCard extends StatelessWidget {
  const _GeneratingAdCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 420,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Generando imagen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
