/// Buyurtma holatlari (`order_status` enum, 0001).
abstract final class OrderStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';

  static const all = <String>[
    pending,
    confirmed,
    inProgress,
    completed,
    cancelled,
  ];

  /// Yopilgan buyurtmani admin ham bekor qila olmaydi
  /// (`admin_cancel_order` `ORDER_ALREADY_CLOSED` beradi, 0010).
  static bool isClosed(String status) =>
      status == completed || status == cancelled;
}

/// Buyurtma ro'yxati qatori.
class AdminOrderRow {
  const AdminOrderRow({
    required this.id,
    required this.status,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.deliveryMethod,
    required this.createdAt,
    required this.respondBy,
    this.cancelledReason,
    this.confirmedAt,
    this.completedAt,
    this.listingTitle,
    this.buyerName,
    this.buyerEmail,
    this.sellerName,
    this.sellerEmail,
  });

  factory AdminOrderRow.fromJson(Map<String, dynamic> json) {
    // Ikkala tomon ham `profiles` ga bogʻlangan, shuning uchun select da
    // FK nomi bilan ajratiladi (`buyer:profiles!orders_buyer_id_fkey`).
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final seller = json['seller'] as Map<String, dynamic>?;
    final listing = json['listings'] as Map<String, dynamic>?;

    return AdminOrderRow(
      id: json['id'] as String,
      status: json['status'] as String? ?? OrderStatus.pending,
      quantity: _num(json['quantity']),
      unitPrice: _num(json['unit_price']),
      totalPrice: _num(json['total_price']),
      deliveryMethod: json['delivery_method'] as String? ?? 'pickup',
      cancelledReason: json['cancelled_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondBy: DateTime.parse(json['respond_by'] as String),
      confirmedAt: _date(json['confirmed_at']),
      completedAt: _date(json['completed_at']),
      listingTitle: listing?['title'] as String?,
      buyerName: buyer?['full_name'] as String?,
      buyerEmail: buyer?['email'] as String?,
      sellerName: seller?['full_name'] as String?,
      sellerEmail: seller?['email'] as String?,
    );
  }

  final String id;
  final String status;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String deliveryMethod;
  final String? cancelledReason;
  final DateTime createdAt;

  /// Sotuvchi javob berishi kerak bo'lgan muddat. O'tib ketgan bo'lsa
  /// `auto_cancel_stale_orders()` cron uni bekor qiladi (0003).
  final DateTime respondBy;

  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final String? listingTitle;
  final String? buyerName;
  final String? buyerEmail;
  final String? sellerName;
  final String? sellerEmail;

  /// Javob muddati o'tgan va hali kutayotgan buyurtma.
  bool get isOverdue =>
      status == OrderStatus.pending && respondBy.isBefore(DateTime.now());

  static double _num(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}

/// Holat tarixi elementi (`order_status_history`, trigger yozadi).
class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.newStatus,
    required this.changedAt,
    this.oldStatus,
    this.reason,
    this.changedByName,
  });

  factory OrderHistoryEntry.fromJson(Map<String, dynamic> json) {
    final by = json['profiles'] as Map<String, dynamic>?;
    return OrderHistoryEntry(
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String? ?? '',
      reason: json['reason'] as String?,
      changedAt: DateTime.parse(json['changed_at'] as String),
      changedByName: by?['full_name'] as String?,
    );
  }

  final String? oldStatus;
  final String newStatus;
  final String? reason;
  final DateTime changedAt;
  final String? changedByName;
}

class OrderFilter {
  const OrderFilter({this.status, this.overdueOnly = false});

  final String? status;

  /// Faqat javob muddati o'tganlar — nizoli holatlar shu yerdan boshlanadi.
  final bool overdueOnly;

  OrderFilter copyWith({
    String? status,
    bool? overdueOnly,
    bool clearStatus = false,
  }) => OrderFilter(
    status: clearStatus ? null : (status ?? this.status),
    overdueOnly: overdueOnly ?? this.overdueOnly,
  );

  bool get isEmpty => status == null && !overdueOnly;
}
