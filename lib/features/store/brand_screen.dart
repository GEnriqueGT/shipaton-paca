import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/guatemala.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';

class BrandScreen extends ConsumerStatefulWidget {
  const BrandScreen({super.key});

  @override
  ConsumerState<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends ConsumerState<BrandScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _color = TextEditingController(text: '#1B5E20');
  String? _department;
  String? _logoUrl;
  bool _loading = false;
  bool _booted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _color.dispose();
    super.dispose();
  }

  void _hydrate(Profile? profile) {
    if (_booted || profile == null) return;
    _booted = true;
    _name.text = profile.displayName ?? '';
    _phone.text = profile.phoneWhatsapp ?? '';
    _color.text = profile.brandColor;
    _department = profile.department;
    _logoUrl = profile.logoUrl;
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
          brandColor: _color.text.trim(),
          logoUrl: _logoUrl,
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
            brandColor: _color.text.trim(),
            logoUrl: _logoUrl,
          ),
        );
        ref.invalidate(profileProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marca guardada')),
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

  @override
  Widget build(BuildContext context) {
    final profile = AppConfig.hasSupabase
        ? ref.watch(profileProvider).valueOrNull
        : DemoStore.instance.profile;
    _hydrate(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Marca de la tienda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'En free el post sale fondo blanco. Con Pro usamos logo y color.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre de tienda'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(
              labelText: 'WhatsApp (502…)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _department,
            items: guatemalaDepartments
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _department = v),
            decoration: const InputDecoration(labelText: 'Departamento'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _color,
            decoration: const InputDecoration(
              labelText: 'Color de marca (#RRGGBB)',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _logoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.store),
                    ),
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
            child: const Text('Guardar marca'),
          ),
        ],
      ),
    );
  }
}
