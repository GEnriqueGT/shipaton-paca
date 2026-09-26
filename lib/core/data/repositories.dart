import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> fetch(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Profile> update(Profile profile) async {
    final data = await _client
        .from('profiles')
        .update(profile.toUpdateJson())
        .eq('id', profile.id)
        .select()
        .single();
    return Profile.fromJson(Map<String, dynamic>.from(data));
  }

  Future<String> uploadLogo(String userId, XFile file) async {
    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final path = '$userId/logo$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from('store-logos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: file.mimeType,
          ),
        );
    return _client.storage.from('store-logos').getPublicUrl(path);
  }

  Future<String> uploadCover(String userId, XFile file) async {
    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final path = '$userId/cover$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from('store-logos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: file.mimeType,
          ),
        );
    return _client.storage.from('store-logos').getPublicUrl(path);
  }

  Future<List<Profile>> listStores() async {
    final rows =
        await _client.from('profiles').select().eq('role', 'store');
    return (rows as List)
        .map((e) => Profile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class PacaRepository {
  PacaRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<List<Paca>> listForStore(String storeId) async {
    final rows = await _client
        .from('pacas')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Paca.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Paca>> listActive({
    String? department,
    String? category,
  }) async {
    var query = _client
        .from('pacas')
        .select(
          '*, profiles(display_name, phone_whatsapp, department)',
        )
        .eq('status', 'active');

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final rows = await query.order('created_at', ascending: false);
    var pacas = (rows as List)
        .map((e) => Paca.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (department != null && department.isNotEmpty) {
      pacas = pacas
          .where((p) => p.storeDepartment == department)
          .toList();
    }
    return pacas;
  }

  Future<Paca> upsert({
    String? id,
    required String storeId,
    required String title,
    required double priceGtq,
    String? description,
    String? category,
    String? sizeMix,
    List<String> photoUrls = const [],
    PacaStatus status = PacaStatus.draft,
  }) async {
    final payload = {
      if (id != null) 'id': id,
      'store_id': storeId,
      'title': title,
      'description': description,
      'price_gtq': priceGtq,
      'category': category,
      'size_mix': sizeMix,
      'photo_urls': photoUrls,
      'status': status.dbValue,
    };
    final data = await _client
        .from('pacas')
        .upsert(payload)
        .select()
        .single();
    return Paca.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(String id) async {
    await _client.from('pacas').delete().eq('id', id);
  }

  Future<void> setStatus(String id, PacaStatus status) async {
    await _client.from('pacas').update({'status': status.dbValue}).eq('id', id);
  }

  Future<void> setAdUrl(String id, String url) async {
    await _client.from('pacas').update({'ad_url': url}).eq('id', id);
  }

  Future<Paca?> fetchById(String id) async {
    final data = await _client
        .from('pacas')
        .select('*, profiles(display_name, phone_whatsapp, department)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Paca.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<Paca>> listPublished(String storeId) async {
    final rows = await _client
        .from('pacas')
        .select()
        .eq('store_id', storeId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Paca.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<String> uploadAdBytes(String storeId, Uint8List bytes) async {
    final path = '$storeId/ad-${_uuid.v4()}.png';
    await _client.storage.from('paca-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );
    return _client.storage.from('paca-photos').getPublicUrl(path);
  }

  Future<String> uploadPhoto(String storeId, XFile file) async {
    final ext = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final path = '$storeId/${_uuid.v4()}$ext';
    final bytes = await file.readAsBytes();
    await _client.storage.from('paca-photos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: file.mimeType,
          ),
        );
    return _client.storage.from('paca-photos').getPublicUrl(path);
  }

  Future<void> logShare({
    required String storeId,
    required String pacaId,
    required String template,
  }) async {
    await _client.from('share_logs').insert({
      'store_id': storeId,
      'paca_id': pacaId,
      'template': template,
    });
  }
}

class PromotionRepository {
  PromotionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Promotion>> listAll() async {
    final rows = await _client
        .from('promotions')
        .select('*, profiles(display_name)')
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => Promotion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Promotion> create({
    required String storeId,
    required String title,
    String? pacaId,
    String? discountLabel,
    bool premiumOnly = true,
  }) async {
    final data = await _client
        .from('promotions')
        .insert({
          'store_id': storeId,
          'title': title,
          'paca_id': pacaId,
          'discount_label': discountLabel,
          'premium_only': premiumOnly,
          'starts_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return Promotion.fromJson(Map<String, dynamic>.from(data));
  }
}

/// In-memory fallback when Supabase keys are missing (local UI demo).
class DemoStore {
  DemoStore._();
  static final instance = DemoStore._();

  Profile? profile;
  final List<Paca> pacas = [];
  final List<Promotion> promotions = [];
  bool storePremium = false;
  bool buyerPremium = false;

  void seedIfNeeded() {
    if (pacas.isNotEmpty) return;
    pacas.add(
      Paca(
        id: 'demo-paca-1',
        storeId: 'demo-user',
        title: 'Paca mix dama — Q200',
        description: 'Ropa americana mixto, tallas S-L',
        priceGtq: 200,
        category: 'Dama',
        sizeMix: 'S-L',
        photoUrls: const [],
        status: PacaStatus.active,
        storeName: 'Pacas Zona 1',
        storePhone: '50255551234',
        storeDepartment: 'Guatemala',
      ),
    );
    promotions.add(
      const Promotion(
        id: 'demo-promo-1',
        storeId: 'demo-user',
        title: '2x1 en zapatos de paca',
        discountLabel: '2x1',
        premiumOnly: true,
        storeName: 'Pacas Zona 1',
      ),
    );
  }
}
