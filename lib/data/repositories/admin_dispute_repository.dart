import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Buyurtma nizolari (`order_disputes`, mobil ilova 0058 migratsiyasi).
///
/// Nizoni buyurtma tomonlaridan biri ilovada ochadi (`open_dispute`). Admin
/// shu yerda ko'radi va qaror yozadi; qaror ikkala tomonga bildirishnoma
/// bo'lib boradi. Ochgan tomon nizoni o'zi ham yopishi mumkin (`closed`).
class AdminDisputeRepository {
  /// `orders` da ikkita ustun `profiles` ga bog'langan, `order_disputes` da
  /// ham ikkita (`opened_by`, `resolved_by`) — shuning uchun har bir embed
  /// FK nomi bilan ko'rsatiladi, aks holda PGRST201.
  ///
  /// Telefon va email faqat `staff_profiles` orqali o'qiladi (mobil 0064).
  static const _select =
      'id, order_id, reason, details, photos, status, resolution, '
      'created_at, resolved_at, '
      'opener:staff_profiles!order_disputes_opened_by_fkey'
      '(full_name, email, phone), '
      'resolver:profiles!order_disputes_resolved_by_fkey(full_name), '
      'orders(status, quantity, total_price, listings(title), '
      'buyer:staff_profiles!orders_buyer_id_fkey(full_name, phone), '
      'seller:staff_profiles!orders_seller_id_fkey(full_name, phone))';

  Future<Result<List<DisputeRow>>> list({String? status}) => guard(() async {
    var query = Db.client.from('order_disputes').select(_select);
    if (status != null) query = query.eq('status', status);

    // Ochiq nizolar — eng eskisi tepada: uzoq kutgan birinchi ko'riladi.
    final rows = await query
        .order('created_at', ascending: status == 'open')
        .limit(AdminConfig.pageSize);
    return [for (final r in rows) DisputeRow.fromJson(r)];
  });

  /// Dalil suratlari — `order-disputes` buketi private, `orders.read`
  /// huquqli xodim signed URL oladi.
  Future<Result<List<String>>> photoUrls(List<String> paths) => guard(() async {
    if (paths.isEmpty) return const <String>[];
    final results = await Db.client.storage
        .from(AdminConfig.bucketOrderDisputes)
        .createSignedUrlsResult(paths, AdminConfig.signedUrlTtl.inSeconds);
    return [
      for (final r in results)
        if (r is SignedUrlSuccess) r.signedUrl,
    ];
  });

  /// `admin_resolve_dispute` RPC `orders.write` ni serverda tekshiradi,
  /// qarorni majburiy qiladi, auditga yozadi va ikkala tomonga xabar beradi.
  Future<Result<void>> resolve(String id, String resolution) => guard(() async {
    await Db.client.rpc<void>(
      'admin_resolve_dispute',
      params: {'p_dispute': id, 'p_resolution': resolution},
    );
  });
}

class DisputeRow {
  const DisputeRow({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.details,
    required this.photos,
    required this.status,
    required this.createdAt,
    required this.openerName,
    this.openerContact,
    this.resolution,
    this.resolvedAt,
    this.resolverName,
    this.orderStatus,
    this.listingTitle,
    this.quantity,
    this.totalPrice,
    this.buyerName,
    this.buyerPhone,
    this.sellerName,
    this.sellerPhone,
  });

  factory DisputeRow.fromJson(Map<String, dynamic> m) {
    Map<String, dynamic> map(Object? v) =>
        (v as Map?)?.cast<String, dynamic>() ?? const {};
    String? text(Object? v) {
      final s = v as String?;
      return (s == null || s.trim().isEmpty) ? null : s;
    }

    final opener = map(m['opener']);
    final order = map(m['orders']);
    final buyer = map(order['buyer']);
    final seller = map(order['seller']);

    return DisputeRow(
      id: m['id'] as String,
      orderId: m['order_id'] as String,
      reason: m['reason'] as String? ?? 'other',
      details: m['details'] as String? ?? '',
      photos: [for (final x in (m['photos'] as List? ?? const [])) '$x'],
      status: m['status'] as String? ?? 'open',
      createdAt: DateTime.parse(m['created_at'] as String),
      resolution: text(m['resolution']),
      resolvedAt: m['resolved_at'] == null
          ? null
          : DateTime.parse(m['resolved_at'] as String),
      resolverName: text(map(m['resolver'])['full_name']),
      openerName: opener['full_name'] as String? ?? '',
      openerContact: text(opener['phone']) ?? text(opener['email']),
      orderStatus: text(order['status']),
      listingTitle: text(map(order['listings'])['title']),
      quantity: (order['quantity'] as num?)?.toDouble(),
      totalPrice: (order['total_price'] as num?)?.toDouble(),
      buyerName: text(buyer['full_name']),
      buyerPhone: text(buyer['phone']),
      sellerName: text(seller['full_name']),
      sellerPhone: text(seller['phone']),
    );
  }

  final String id;
  final String orderId;

  /// `not_received` | `quality` | `quantity` | `payment` | `behavior` | `other`
  final String reason;
  final String details;

  /// `order-disputes` buketidagi yo'llar (5 tagacha).
  final List<String> photos;

  /// `open` | `resolved` (admin qarori) | `closed` (ochgan tomon yopgan)
  final String status;
  final DateTime createdAt;
  final String? resolution;
  final DateTime? resolvedAt;
  final String? resolverName;

  final String openerName;
  final String? openerContact;

  final String? orderStatus;
  final String? listingTitle;
  final double? quantity;
  final double? totalPrice;
  final String? buyerName;
  final String? buyerPhone;
  final String? sellerName;
  final String? sellerPhone;

  bool get isOpen => status == 'open';

  /// Buyurtmaning qisqa raqami — ro'yxatda va qidiruvda qulay.
  String get orderShortId =>
      orderId.length <= 8 ? orderId : orderId.substring(0, 8);
}
