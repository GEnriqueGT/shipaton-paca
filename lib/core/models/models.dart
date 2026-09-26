enum UserRole {
  store,
  buyer;

  String get dbValue => name;

  static UserRole? tryParse(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }
}

class Profile {
  const Profile({
    required this.id,
    this.role,
    this.displayName,
    this.department,
    this.phoneWhatsapp,
    this.logoUrl,
    this.coverUrl,
    this.brandColor = '#1B5E20',
  });

  final String id;
  final UserRole? role;
  final String? displayName;
  final String? department;
  final String? phoneWhatsapp;
  final String? logoUrl;
  final String? coverUrl;
  final String brandColor;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: UserRole.tryParse(json['role'] as String?),
      displayName: json['display_name'] as String?,
      department: json['department'] as String?,
      phoneWhatsapp: json['phone_whatsapp'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      brandColor: (json['brand_color'] as String?) ?? '#1B5E20',
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (role != null) 'role': role!.dbValue,
      if (displayName != null) 'display_name': displayName,
      if (department != null) 'department': department,
      if (phoneWhatsapp != null) 'phone_whatsapp': phoneWhatsapp,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (coverUrl != null) 'cover_url': coverUrl,
      'brand_color': brandColor,
    };
  }

  Profile copyWith({
    UserRole? role,
    String? displayName,
    String? department,
    String? phoneWhatsapp,
    String? logoUrl,
    String? coverUrl,
    String? brandColor,
  }) {
    return Profile(
      id: id,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      department: department ?? this.department,
      phoneWhatsapp: phoneWhatsapp ?? this.phoneWhatsapp,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      brandColor: brandColor ?? this.brandColor,
    );
  }
}

enum PacaStatus {
  draft,
  active,
  sold;

  String get dbValue => name;

  static PacaStatus parse(String value) {
    return PacaStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PacaStatus.draft,
    );
  }
}

class Paca {
  const Paca({
    required this.id,
    required this.storeId,
    required this.title,
    required this.priceGtq,
    this.description,
    this.category,
    this.sizeMix,
    this.photoUrls = const [],
    this.adUrl,
    this.status = PacaStatus.draft,
    this.createdAt,
    this.storeName,
    this.storePhone,
    this.storeDepartment,
  });

  final String id;
  final String storeId;
  final String title;
  final String? description;
  final double priceGtq;
  final String? category;
  final String? sizeMix;
  final List<String> photoUrls;
  final String? adUrl;
  final PacaStatus status;

  /// AI ad when it exists, otherwise the original photo.
  String? get heroUrl {
    if (adUrl != null && adUrl!.isNotEmpty) return adUrl;
    if (photoUrls.isNotEmpty) return photoUrls.first;
    return null;
  }
  final DateTime? createdAt;
  final String? storeName;
  final String? storePhone;
  final String? storeDepartment;

  factory Paca.fromJson(Map<String, dynamic> json) {
    final photos = json['photo_urls'];
    final store = json['profiles'] as Map<String, dynamic>?;
    return Paca(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceGtq: (json['price_gtq'] as num).toDouble(),
      category: json['category'] as String?,
      sizeMix: json['size_mix'] as String?,
      photoUrls: photos is List
          ? photos.map((e) => e.toString()).toList()
          : const [],
      adUrl: json['ad_url'] as String?,
      status: PacaStatus.parse((json['status'] as String?) ?? 'draft'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      storeName: store?['display_name'] as String?,
      storePhone: store?['phone_whatsapp'] as String?,
      storeDepartment: store?['department'] as String?,
    );
  }
}

class Promotion {
  const Promotion({
    required this.id,
    required this.storeId,
    required this.title,
    this.pacaId,
    this.discountLabel,
    this.startsAt,
    this.endsAt,
    this.premiumOnly = true,
    this.storeName,
  });

  final String id;
  final String storeId;
  final String? pacaId;
  final String title;
  final String? discountLabel;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool premiumOnly;
  final String? storeName;

  factory Promotion.fromJson(Map<String, dynamic> json) {
    final store = json['profiles'] as Map<String, dynamic>?;
    return Promotion(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      pacaId: json['paca_id'] as String?,
      title: json['title'] as String,
      discountLabel: json['discount_label'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
      premiumOnly: (json['premium_only'] as bool?) ?? true,
      storeName: store?['display_name'] as String?,
    );
  }
}
