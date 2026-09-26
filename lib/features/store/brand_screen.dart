import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/guatemala.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../share/post_templates.dart';

class BrandScreen extends ConsumerStatefulWidget {
  const BrandScreen({super.key});

  @override
  ConsumerState<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends ConsumerState<BrandScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  Color _color = const Color(0xFF1B5E20);
  String? _department;
  String? _logoUrl;
  String? _coverUrl;
  bool _loading = false;
  bool _booted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _hydrate(Profile? profile) {
    if (_booted || profile == null) return;
    _booted = true;
    _name.text = profile.displayName ?? '';
    _phone.text = profile.phoneWhatsapp ?? '';
    _color = parseHexColor(profile.brandColor);
    _department = profile.department;
    _logoUrl = profile.logoUrl;
    _coverUrl = profile.coverUrl;
  }

  String get _hex {
    final rgb = _color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      if (!AppConfig.hasSupabase) {
        setState(() => _logoUrl = file.path);
        return;
      }
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final url = await ProfileRepository(ref.read(supabaseProvider))
          .uploadLogo(user.id, file);
      setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCover() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    try {
      if (!AppConfig.hasSupabase) {
        setState(() => _coverUrl = file.path);
        return;
      }
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final url = await ProfileRepository(ref.read(supabaseProvider))
          .uploadCover(user.id, file);
      setState(() => _coverUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error portada: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      if (!AppConfig.hasSupabase) {
        final current = DemoStore.instance.profile;
        DemoStore.instance.profile = (current ??
                const Profile(id: 'demo-user', role: UserRole.store))
            .copyWith(
          displayName: _name.text.trim(),
          phoneWhatsapp: _phone.text.trim(),
          department: _department,
          brandColor: _hex,
          logoUrl: _logoUrl,
          coverUrl: _coverUrl,
        );
      } else {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        final repo = ProfileRepository(ref.read(supabaseProvider));
        final existing = await repo.fetch(user.id);
        await repo.update(
          (existing ?? Profile(id: user.id)).copyWith(
            displayName: _name.text.trim(),
            phoneWhatsapp: _phone.text.trim(),
            department: _department,
            brandColor: _hex,
            logoUrl: _logoUrl,
            coverUrl: _coverUrl,
          ),
        );
        ref.invalidate(profileProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    if (AppConfig.hasSupabase) {
      await ref.read(customerInfoProvider.notifier).logOut();
      await ref.read(supabaseProvider).auth.signOut();
    }
    if (mounted) context.go('/auth');
  }

  Future<void> _changeRole() async {
    if (AppConfig.hasSupabase) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(supabaseProvider).from('profiles').update({
          'role': null,
        }).eq('id', user.id);
        ref.invalidate(profileProvider);
        await ref.read(profileProvider.future);
      }
    } else {
      final current = DemoStore.instance.profile;
      if (current != null) {
        DemoStore.instance.profile = Profile(
          id: current.id,
          displayName: current.displayName,
          department: current.department,
          phoneWhatsapp: current.phoneWhatsapp,
          logoUrl: current.logoUrl,
          coverUrl: current.coverUrl,
          brandColor: current.brandColor,
        );
      }
    }
    if (mounted) context.go('/role');
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppConfig.hasSupabase
        ? ref.watch(profileProvider).valueOrNull
        : DemoStore.instance.profile;
    _hydrate(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Así se ve tu tienda para quien entra a comprar.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: _coverUrl != null && _coverUrl!.isNotEmpty
                  ? CachedNetworkImage(imageUrl: _coverUrl!, fit: BoxFit.cover)
                  : ColoredBox(color: _color),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickCover,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Cambiar portada'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre de la tienda'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'WhatsApp (502…)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _department,
            items: guatemalaDepartments
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _department = v),
            decoration: const InputDecoration(labelText: 'Departamento'),
          ),
          const SizedBox(height: 16),
          Text('Color de la tienda', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          HueRingPicker(
            pickerColor: _color,
            onColorChanged: (color) => setState(() => _color = color),
            displayThumbColor: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_logoUrl != null && _logoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _logoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickLogo,
                icon: const Icon(Icons.upload),
                label: const Text('Subir logo'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: const Text('Guardar perfil'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loading ? null : _changeRole,
            child: const Text('Cambiar rol'),
          ),
          TextButton(
            onPressed: _loading ? null : _signOut,
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
