/// Xo'jalik ro'yxati qatori (`farms` + egasi + viloyat).
class AdminFarmRow {
  const AdminFarmRow({
    required this.id,
    required this.name,
    required this.areaHectares,
    required this.irrigation,
    required this.createdAt,
    this.ownerName,
    this.ownerEmail,
    this.ownerId,
    this.regionName,
    this.districtName,
    this.fieldCount = 0,
  });

  factory AdminFarmRow.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    final owner = json['profiles'] as Map<String, dynamic>?;
    final region = json['regions'] as Map<String, dynamic>?;
    final district = json['districts'] as Map<String, dynamic>?;

    // PostgREST agregatni `[{count: n}]` shaklida qaytaradi.
    final fields = json['fields'];
    final count = switch (fields) {
      List list when list.isNotEmpty && list.first is Map =>
        (list.first as Map)['count'] as int? ?? 0,
      _ => 0,
    };

    return AdminFarmRow(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      areaHectares: _num(json['area_hectares']),
      irrigation: json['irrigation'] as String? ?? 'furrow',
      createdAt: DateTime.parse(json['created_at'] as String),
      ownerId: owner?['id'] as String?,
      ownerName: owner?['full_name'] as String?,
      ownerEmail: owner?['email'] as String?,
      regionName: region?['name_$locale'] as String?,
      districtName: district?['name_$locale'] as String?,
      fieldCount: count,
    );
  }

  final String id;
  final String name;
  final double areaHectares;
  final String irrigation;
  final DateTime createdAt;
  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;
  final String? regionName;
  final String? districtName;
  final int fieldCount;

  static double _num(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}

/// Dala — xo'jalik tafsilotida.
class AdminFieldRow {
  const AdminFieldRow({
    required this.id,
    required this.name,
    required this.areaHectares,
    required this.health,
    this.healthScore,
    this.cropName,
    this.growthPercent,
    this.hasBoundary = false,
  });

  factory AdminFieldRow.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    // Faol (arxivlanmagan) ekin — dalada bittadan ortiq bo'lishi mumkin,
    // birinchisi ko'rsatiladi.
    final crops = json['field_crops'];
    Map<String, dynamic>? crop;
    if (crops is List) {
      for (final entry in crops) {
        if (entry is Map && entry['is_archived'] != true) {
          crop = Map<String, dynamic>.from(entry);
          break;
        }
      }
    }
    final cropType = crop?['crop_types'] as Map<String, dynamic>?;

    return AdminFieldRow(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      areaHectares: AdminFarmRow._num(json['area_hectares']),
      health: json['health'] as String? ?? 'healthy',
      healthScore: (json['health_score'] as num?)?.toInt(),
      cropName: cropType?['name_$locale'] as String?,
      growthPercent: (crop?['growth_percent'] as num?)?.toInt(),
      hasBoundary: json['boundary_geojson'] != null,
    );
  }

  final String id;
  final String name;
  final double areaHectares;
  final String health;
  final int? healthScore;
  final String? cropName;
  final int? growthPercent;

  /// Xaritada chizilgan chegara bormi (`boundary_geojson`).
  final bool hasBoundary;
}

/// Xo'jaliklar filtri.
class FarmFilter {
  const FarmFilter({this.search = '', this.regionId, this.irrigation});

  /// Xo'jalik nomi bo'yicha.
  ///
  /// Egasining ismi bo'yicha qidiruv YO'Q: PostgREST bog'langan jadval
  /// ustunida `or` filtrini qo'llab-quvvatlamaydi, buning uchun alohida
  /// view yoki RPC kerak bo'lardi. Egasini topish uchun Foydalanuvchilar
  /// moduli ishlatiladi.
  final String search;

  final int? regionId;
  final String? irrigation;

  FarmFilter copyWith({
    String? search,
    int? regionId,
    String? irrigation,
    bool clearRegion = false,
    bool clearIrrigation = false,
  }) => FarmFilter(
    search: search ?? this.search,
    regionId: clearRegion ? null : (regionId ?? this.regionId),
    irrigation: clearIrrigation ? null : (irrigation ?? this.irrigation),
  );

  bool get isEmpty => search.isEmpty && regionId == null && irrigation == null;
}
