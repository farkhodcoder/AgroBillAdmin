/// Foydalanuvchi ro'yxati qatori.
///
/// `profiles` + `regions` (nom uchun) + `subscriptions` (premium belgisi).
class AdminUserRow {
  const AdminUserRow({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.activity,
    required this.isBlocked,
    required this.createdAt,
    this.blockReason,
    this.regionName,
    this.districtName,
    this.phone,
    this.isPremium = false,
    this.deletedAt,
    this.rating = 0,
    this.ratingCount = 0,
  });

  factory AdminUserRow.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    final region = json['regions'] as Map<String, dynamic>?;
    final district = json['districts'] as Map<String, dynamic>?;

    // PostgREST `!inner` siz bog'langan jadvalni ro'yxat sifatida ham
    // qaytarishi mumkin — ikkala shakl ham qo'llab-quvvatlanadi.
    final subs = json['subscriptions'];
    final premium = switch (subs) {
      List list => list.any(
        (s) => s is Map && s['is_active'] == true && s['plan'] == 'premium',
      ),
      Map m => m['is_active'] == true && m['plan'] == 'premium',
      _ => false,
    };

    return AdminUserRow(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'farmer',
      activity: json['activity'] as String? ?? 'other',
      isBlocked: json['is_blocked'] as bool? ?? false,
      blockReason: json['block_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      regionName: region?['name_$locale'] as String?,
      districtName: district?['name_$locale'] as String?,
      isPremium: premium,
      rating: _num(json['rating']),
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final String activity;
  final bool isBlocked;
  final String? blockReason;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final String? regionName;
  final String? districtName;
  final bool isPremium;
  final double rating;
  final int ratingCount;

  bool get isDeleted => deletedAt != null;

  static double _num(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}

/// Foydalanuvchi ro'yxati filtri.
class UserFilter {
  const UserFilter({
    this.search = '',
    this.role,
    this.regionId,
    this.activity,
    this.blocked,
  });

  /// `full_name`, `email` yoki `id` bo'yicha.
  ///
  /// TELEFON BO'YICHA QIDIRUV YO'Q (TTZ §6.2): `profiles.phone` `0005` da
  /// nullable qilingan va ro'yxatdan o'tishda umuman so'ralmaydi.
  final String search;

  final String? role;
  final int? regionId;
  final String? activity;
  final bool? blocked;

  UserFilter copyWith({
    String? search,
    String? role,
    int? regionId,
    String? activity,
    bool? blocked,
    bool clearRole = false,
    bool clearRegion = false,
    bool clearActivity = false,
    bool clearBlocked = false,
  }) => UserFilter(
    search: search ?? this.search,
    role: clearRole ? null : (role ?? this.role),
    regionId: clearRegion ? null : (regionId ?? this.regionId),
    activity: clearActivity ? null : (activity ?? this.activity),
    blocked: clearBlocked ? null : (blocked ?? this.blocked),
  );

  bool get isEmpty =>
      search.isEmpty &&
      role == null &&
      regionId == null &&
      activity == null &&
      blocked == null;
}

/// Ma'lumotnoma elementi (viloyat, ekin turi).
class RefItem {
  const RefItem({required this.id, required this.name});

  final int id;
  final String name;
}
