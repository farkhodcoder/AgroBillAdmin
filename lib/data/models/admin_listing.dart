/// E'lon holatlari.
///
/// `changes_requested` va `suspended` — `0011_moderation.sql` da qo'shilgan.
/// Mobil ilova ularni hech qachon yozmaydi, faqat admin qo'yadi.
abstract final class ListingStatus {
  static const pending = 'pending';
  static const active = 'active';
  static const rejected = 'rejected';
  static const changesRequested = 'changes_requested';
  static const suspended = 'suspended';
  static const archived = 'archived';
  static const sold = 'sold';

  static const all = <String>[
    pending,
    active,
    changesRequested,
    rejected,
    suspended,
    archived,
    sold,
  ];

  /// Moderator qo'ya oladigan holatlar (`admin_moderate_listing` qabul
  /// qiladiganlar, 0011).
  static const moderatable = <String>[
    active,
    changesRequested,
    rejected,
    suspended,
    archived,
  ];

  /// Salbiy qaror — sabab majburiy (baza ham `REASON_REQUIRED` beradi).
  static bool needsReason(String status) =>
      status == rejected || status == changesRequested || status == suspended;
}

/// E'lon ro'yxati qatori.
class AdminListingRow {
  const AdminListingRow({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.createdAt,
    required this.expiresAt,
    this.description,
    this.rejectReason,
    this.sellerId,
    this.sellerName,
    this.sellerEmail,
    this.regionName,
    this.cropName,
    this.viewCount = 0,
    this.imagePaths = const [],
  });

  factory AdminListingRow.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    final seller = json['profiles'] as Map<String, dynamic>?;
    final region = json['regions'] as Map<String, dynamic>?;
    final crop = json['crop_types'] as Map<String, dynamic>?;

    final images = json['listing_images'];
    final paths = <String>[];
    if (images is List) {
      final sorted = [...images]
        ..sort(
          (a, b) => ((a as Map)['sort_order'] as int? ?? 0).compareTo(
            ((b as Map)['sort_order'] as int? ?? 0),
          ),
        );
      for (final img in sorted) {
        final path = (img as Map)['storage_path'] as String?;
        if (path != null) paths.add(path);
      }
    }

    return AdminListingRow(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? ListingStatus.pending,
      price: _num(json['price']),
      quantity: _num(json['quantity']),
      unit: json['unit'] as String? ?? 'kg',
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      rejectReason: json['reject_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      sellerId: seller?['id'] as String?,
      sellerName: seller?['full_name'] as String?,
      sellerEmail: seller?['email'] as String?,
      regionName: region?['name_$locale'] as String?,
      cropName: crop?['name_$locale'] as String?,
      imagePaths: paths,
    );
  }

  final String id;
  final String title;
  final String status;
  final double price;
  final double quantity;
  final String unit;
  final String category;
  final String? description;
  final String? rejectReason;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final String? sellerId;
  final String? sellerName;
  final String? sellerEmail;
  final String? regionName;
  final String? cropName;

  /// `listing_images.storage_path` — signed URL alohida olinadi.
  final List<String> imagePaths;

  static double _num(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}

/// Moderatsiya tarixi elementi (`listing_moderation_history`, 0011).
class ModerationEntry {
  const ModerationEntry({
    required this.newStatus,
    required this.createdAt,
    this.oldStatus,
    this.reason,
    this.moderatorName,
  });

  factory ModerationEntry.fromJson(Map<String, dynamic> json) {
    final mod = json['profiles'] as Map<String, dynamic>?;
    return ModerationEntry(
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String? ?? '',
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      moderatorName: mod?['full_name'] as String?,
    );
  }

  final String? oldStatus;
  final String newStatus;
  final String? reason;
  final DateTime createdAt;
  final String? moderatorName;
}

class ListingFilter {
  const ListingFilter({this.search = '', this.status, this.regionId});

  final String search;
  final String? status;
  final int? regionId;

  ListingFilter copyWith({
    String? search,
    String? status,
    int? regionId,
    bool clearStatus = false,
    bool clearRegion = false,
  }) => ListingFilter(
    search: search ?? this.search,
    status: clearStatus ? null : (status ?? this.status),
    regionId: clearRegion ? null : (regionId ?? this.regionId),
  );

  bool get isEmpty => search.isEmpty && status == null && regionId == null;
}
