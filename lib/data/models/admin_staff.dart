/// Xodim yozuvi (`admin_users` + `profiles`).
class StaffRow {
  const StaffRow({
    required this.id,
    required this.roleCode,
    required this.isActive,
    required this.languageCode,
    required this.createdAt,
    this.fullName,
    this.email,
    this.lastLoginAt,
  });

  factory StaffRow.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return StaffRow(
      id: json['id'] as String,
      roleCode: json['role_code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      languageCode: json['language_code'] as String? ?? 'uz',
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: json['last_login_at'] == null
          ? null
          : DateTime.parse(json['last_login_at'] as String),
      fullName: profile?['full_name'] as String?,
      email: profile?['email'] as String?,
    );
  }

  final String id;
  final String roleCode;
  final bool isActive;
  final String languageCode;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? fullName;
  final String? email;
}

/// Kirish hodisasi (`admin_login_events`).
class LoginEvent {
  const LoginEvent({
    required this.id,
    required this.success,
    required this.createdAt,
    this.email,
    this.failureCode,
    this.ipAddress,
    this.userAgent,
  });

  factory LoginEvent.fromJson(Map<String, dynamic> json) => LoginEvent(
    id: json['id'] as String,
    success: json['success'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    email: json['email'] as String?,
    failureCode: json['failure_code'] as String?,
    ipAddress: json['ip_address'] as String?,
    userAgent: json['user_agent'] as String?,
  );

  final String id;
  final bool success;
  final DateTime createdAt;
  final String? email;
  final String? failureCode;
  final String? ipAddress;
  final String? userAgent;
}

/// Rol va unga biriktirilgan ruxsatlar.
class RoleWithPermissions {
  const RoleWithPermissions({
    required this.code,
    required this.name,
    required this.permissions,
  });

  final String code;
  final String name;
  final Set<String> permissions;
}

/// Tizim sozlamasi (`app_settings`, 0017).
class AppSetting {
  const AppSetting({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
    this.updatedByName,
  });

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    final by = json['profiles'] as Map<String, dynamic>?;
    return AppSetting(
      key: json['key'] as String,
      // `value` — `jsonb`. Sonlar, matnlar va boolean bir xil maydonda
      // yotadi, shuning uchun tahrirlashda xom JSON ko'rsatiladi.
      value: json['value'],
      description: json['description'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      updatedByName: by?['full_name'] as String?,
    );
  }

  final String key;
  final Object? value;
  final String? description;
  final DateTime? updatedAt;
  final String? updatedByName;

  /// Ko'rsatish uchun — `"15"` emas, `15`.
  String get display => switch (value) {
    null => '—',
    String s => s,
    _ => value.toString(),
  };
}

/// CMS yozuvi (`content_items`, 0013).
class ContentRow {
  const ContentRow({
    required this.id,
    required this.kind,
    required this.slug,
    required this.status,
    required this.titleUz,
    required this.createdAt,
    this.titleRu,
    this.titleEn,
    this.bodyUz,
    this.bodyRu,
    this.bodyEn,
    this.publishedAt,
    this.authorName,
    this.cropName,
  });

  factory ContentRow.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    final author = json['profiles'] as Map<String, dynamic>?;
    final crop = json['crop_types'] as Map<String, dynamic>?;

    return ContentRow(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'article',
      slug: json['slug'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      titleUz: json['title_uz'] as String? ?? '',
      titleRu: json['title_ru'] as String?,
      titleEn: json['title_en'] as String?,
      bodyUz: json['body_uz'] as String?,
      bodyRu: json['body_ru'] as String?,
      bodyEn: json['body_en'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      authorName: author?['full_name'] as String?,
      cropName: crop?['name_$locale'] as String?,
    );
  }

  final String id;
  final String kind;
  final String slug;
  final String status;
  final String titleUz;
  final String? titleRu;
  final String? titleEn;
  final String? bodyUz;
  final String? bodyRu;
  final String? bodyEn;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? authorName;
  final String? cropName;

  /// `content_translation_state()` bilan bir xil mantiq (0013).
  ///
  /// Funksiya PostgREST orqali hisoblanadigan maydon sifatida ham
  /// chaqirilishi mumkin edi, lekin u har qator uchun alohida hisoblanadi;
  /// bu yerda maydonlar allaqachon olingan, shuning uchun mijozda.
  String get translationState {
    final hasRu = (titleRu?.isNotEmpty ?? false);
    final hasEn = (titleEn?.isNotEmpty ?? false);
    final hasBodyRu = (bodyRu?.isNotEmpty ?? false);
    final hasBodyEn = (bodyEn?.isNotEmpty ?? false);

    if (hasRu && hasEn && hasBodyRu && hasBodyEn) return 'complete';
    if (hasRu || hasEn) return 'partial';
    return 'missing';
  }
}

/// Kontent turlari (`content_kind` enum, 0013).
abstract final class ContentKind {
  static const article = 'article';
  static const guide = 'guide';
  static const faq = 'faq';
  static const announcement = 'announcement';
  static const banner = 'banner';

  static const all = <String>[article, guide, faq, announcement, banner];
}
