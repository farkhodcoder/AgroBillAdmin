import '../../core/i18n/ref_name.dart';
import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Faqat o'qiladigan ikki navbat: hisobni o'chirish so'rovlari va xaridor
/// so'rovlari. Ikkalasida ham admin amal bajarmaydi — kuzatadi.
class AdminRequestRepository {
  // --- Hisobni o'chirish (`account_deletion_requests`, 0006) -------------------

  /// O'chirishni `process_account_deletions` cron'i bajaradi (har kuni
  /// 03:30 UTC). Bu ro'yxat kim ketayotganini va qachon o'chishini
  /// ko'rsatadi — masalan, ochiq buyurtmasi bor sotuvchi bilan bog'lanish
  /// uchun.
  Future<Result<List<DeletionRequest>>> deletionRequests({String? status}) =>
      guard(() async {
        var query = Db.client
            .from('account_deletion_requests')
            .select(
              'id, user_id, requested_at, scheduled_deletion_at, status, '
              'profiles:staff_profiles(full_name, email, phone)',
            );
        if (status != null) query = query.eq('status', status);

        final rows = await query
            .order('scheduled_deletion_at', ascending: status == 'pending')
            .limit(AdminConfig.pageSize * 2);
        return [for (final r in rows) DeletionRequest.fromJson(r)];
      });

  // --- Xaridor so'rovlari (`market_requests`, 0052) ----------------------------

  /// `market_requests` va `request_offers` orasida IKKITA bog'lanish bor
  /// (`request_id` va `accepted_offer_id`), shuning uchun takliflar FK nomi
  /// bilan olinadi — aks holda PGRST201.
  static const _requestSelect =
      'id, title, category, quantity, unit, quality, needed_by, '
      'target_price, note, status, offers_count, expires_at, created_at, '
      'buyer:staff_profiles!market_requests_buyer_id_fkey(full_name, phone), '
      'regions(name_uz, name_ru, name_en), '
      'offers:request_offers!request_offers_request_id_fkey('
      'id, price, quantity, note, status, created_at, '
      'farmer:staff_profiles!request_offers_farmer_id_fkey(full_name, phone))';

  Future<Result<List<MarketRequest>>> marketRequests({
    String? status,
    String locale = 'uz',
  }) => guard(() async {
    var query = Db.client.from('market_requests').select(_requestSelect);
    if (status != null) query = query.eq('status', status);

    final rows = await query
        .order('created_at', ascending: false)
        .limit(AdminConfig.pageSize);
    return [for (final r in rows) MarketRequest.fromJson(r, locale: locale)];
  });
}

class DeletionRequest {
  const DeletionRequest({
    required this.id,
    required this.userId,
    required this.requestedAt,
    required this.scheduledAt,
    required this.status,
    this.fullName,
    this.contact,
  });

  factory DeletionRequest.fromJson(Map<String, dynamic> m) {
    final p = (m['profiles'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? text(Object? v) {
      final s = v as String?;
      return (s == null || s.trim().isEmpty) ? null : s;
    }

    return DeletionRequest(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      requestedAt: DateTime.parse(m['requested_at'] as String),
      scheduledAt: DateTime.parse(m['scheduled_deletion_at'] as String),
      status: m['status'] as String? ?? 'pending',
      fullName: text(p['full_name']),
      contact: text(p['phone']) ?? text(p['email']),
    );
  }

  final String id;
  final String userId;
  final DateTime requestedAt;
  final DateTime scheduledAt;

  /// `pending` | `cancelled` | `completed`
  final String status;
  final String? fullName;
  final String? contact;

  bool get isPending => status == 'pending';

  /// O'chirilishigacha qolgan to'liq kunlar (manfiy bo'lmaydi).
  int daysLeft(DateTime now) {
    final days = scheduledAt.difference(now).inDays;
    return days < 0 ? 0 : days;
  }
}

class MarketRequest {
  const MarketRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.createdAt,
    required this.offers,
    this.quality,
    this.neededBy,
    this.targetPrice,
    this.note,
    this.expiresAt,
    this.buyerName,
    this.buyerPhone,
    this.regionName,
  });

  factory MarketRequest.fromJson(
    Map<String, dynamic> m, {
    String locale = 'uz',
  }) {
    final buyer = (m['buyer'] as Map?)?.cast<String, dynamic>() ?? const {};
    DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);

    return MarketRequest(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      category: m['category'] as String? ?? 'other',
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
      unit: m['unit'] as String? ?? 'kg',
      quality: m['quality'] as String?,
      neededBy: date(m['needed_by']),
      targetPrice: (m['target_price'] as num?)?.toDouble(),
      note: m['note'] as String?,
      status: m['status'] as String? ?? 'open',
      expiresAt: date(m['expires_at']),
      createdAt: DateTime.parse(m['created_at'] as String),
      buyerName: buyer['full_name'] as String?,
      buyerPhone: buyer['phone'] as String?,
      regionName: refName(
        (m['regions'] as Map?)?.cast<String, dynamic>(),
        locale,
      ),
      offers: [
        for (final o in (m['offers'] as List? ?? const []))
          RequestOffer.fromJson(Map<String, dynamic>.from(o as Map)),
      ]..sort((a, b) => a.price.compareTo(b.price)),
    );
  }

  final String id;
  final String title;
  final String category;
  final double quantity;

  /// `kg` | `t` | `dona`
  final String unit;
  final String? quality;
  final DateTime? neededBy;
  final double? targetPrice;
  final String? note;

  /// `open` | `fulfilled` | `cancelled` | `expired`
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String? buyerName;
  final String? buyerPhone;
  final String? regionName;

  /// Takliflar — arzonidan boshlab.
  final List<RequestOffer> offers;

  bool get isOpen => status == 'open';
}

class RequestOffer {
  const RequestOffer({
    required this.id,
    required this.price,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.note,
    this.farmerName,
    this.farmerPhone,
  });

  factory RequestOffer.fromJson(Map<String, dynamic> m) {
    final farmer = (m['farmer'] as Map?)?.cast<String, dynamic>() ?? const {};
    return RequestOffer(
      id: m['id'] as String,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
      note: m['note'] as String?,
      status: m['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(m['created_at'] as String),
      farmerName: farmer['full_name'] as String?,
      farmerPhone: farmer['phone'] as String?,
    );
  }

  final String id;
  final double price;
  final double quantity;
  final String? note;

  /// `pending` | `accepted` | `declined` | `withdrawn`
  final String status;
  final DateTime createdAt;
  final String? farmerName;
  final String? farmerPhone;
}
