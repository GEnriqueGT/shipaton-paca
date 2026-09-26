import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/guatemala.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import 'my_pacas_screen.dart';

class PacaFormScreen extends ConsumerStatefulWidget {
  const PacaFormScreen({super.key, this.pacaId});

  final String? pacaId;

  @override
  ConsumerState<PacaFormScreen> createState() => _PacaFormScreenState();
}

class _PacaFormScreenState extends ConsumerState<PacaFormScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _sizeMix = TextEditingController();
  String? _category = pacaCategories.first;
  PacaStatus _status = PacaStatus.draft;
  final List<String> _photoUrls = [];
  bool _loading = false;
  bool _booted = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _sizeMix.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (widget.pacaId == null || _booted) return;
    _booted = true;
    List<Paca> list;
    if (!AppConfig.hasSupabase) {
      list = DemoStore.instance.pacas;
    } else {
      list = await ref.read(storePacasProvider.future);
    }
    final paca = list.where((p) => p.id == widget.pacaId).firstOrNull;
    if (paca == null || !mounted) return;
    setState(() {
      _title.text = paca.title;
      _description.text = paca.description ?? '';
      _price.text = paca.priceGtq.toStringAsFixed(0);
      _sizeMix.text = paca.sizeMix ?? '';
      _category = paca.category ?? pacaCategories.first;
      _status = paca.status;
      _photoUrls
        ..clear()
        ..addAll(paca.photoUrls);
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _loading = true);
    try {
      if (!AppConfig.hasSupabase) {
        setState(() => _photoUrls.add(file.path));
        return;
      }
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      final url =
          await PacaRepository(ref.read(supabaseProvider)).uploadPhoto(user.id, file);
      setState(() => _photoUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }
    if (_photoUrls.isEmpty && _status == PacaStatus.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos 1 foto para activar')),
      );
      return;
    }
    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;
    setState(() => _loading = true);
    try {
      if (!AppConfig.hasSupabase) {
        final id = widget.pacaId ?? 'demo-${DateTime.now().millisecondsSinceEpoch}';
        final store = DemoStore.instance;
        store.pacas.removeWhere((p) => p.id == id);
        store.pacas.insert(
          0,
          Paca(
            id: id,
            storeId: 'demo-user',
            title: _title.text.trim(),
            description: _description.text.trim(),
            priceGtq: price,
            category: _category,
            sizeMix: _sizeMix.text.trim(),
            photoUrls: List.from(_photoUrls),
            status: _status,
            storeName: store.profile?.displayName,
            storePhone: store.profile?.phoneWhatsapp,
            storeDepartment: store.profile?.department,
          ),
        );
      } else {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        await PacaRepository(ref.read(supabaseProvider)).upsert(
          id: widget.pacaId,
          storeId: user.id,
          title: _title.text.trim(),
          description: _description.text.trim(),
          priceGtq: price,
          category: _category,
          sizeMix: _sizeMix.text.trim(),
          photoUrls: _photoUrls,
          status: _status,
        );
      }
      ref.invalidate(storePacasProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadExisting();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pacaId == null ? 'Nueva paca' : 'Editar paca'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio (GTQ)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _category,
            items: pacaCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sizeMix,
            decoration: const InputDecoration(labelText: 'Tallas / mix'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PacaStatus>(
            // ignore: deprecated_member_use
            value: _status,
            items: PacaStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.dbValue),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? PacaStatus.draft),
            decoration: const InputDecoration(labelText: 'Estado'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._photoUrls.map(
                (url) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      // fallback for local demo file paths
                      'assets/.keep',
                      errorBuilder: (_, __, ___) => Container(
                        width: 88,
                        height: 88,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Foto'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
