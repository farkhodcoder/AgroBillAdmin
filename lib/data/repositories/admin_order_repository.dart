import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_order.dart';

/// Buyurtmalar (TTZ §6.5).
///
/// Admin faqat NIZOLI holatda aralashadi — `admin_cancel_order()` (0010).
/// Holat oqimining qolgani mobil ilovada: sotuvchi tasdiqlaydi, xaridor
/// qabul qiladi, `auto_cancel_stale_orders()` cron javobsizlarni yopadi.
///
/// TO'LOV HOLATI YO'Q: `orders` da to'lovga oid ustun umuman yo'q va to'lov
/// tizimi ulanmagan (TTZ §6.5). v2.1 dagi "Payment status" bajarilmaydi.
class AdminOrderRepository {
  /// `buyer` va `seller` — ikkalasi ham `profiles` ga bogʻlangan, shuning
  /// uchun PostgREST ga QAYSI FK ekanini aytish kerak (`!fk_nomi`), aks
  /// holda PGRST201 "bir nechta bogʻlanish topildi" xatosi chiqadi.
  static const _select =
      'id, status, quantity, unit_price, total_price, delivery_method, '
      'cancelled_reason, created_at, respond_by, confirmed_at, completed_at, '
      'listings(title), '
      'buyer:profiles!orders_buyer_id_fkey(full_name, email), '
      'seller:profiles!orders_seller_id_fkey(full_name, email)';

  Future<Result<List<AdminOrderRow>>> list({
    required OrderFilter filter,
    required int page,
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client.from('orders').select(_select);

    if (filter.status != null) query = query.eq('status', filter.status!);

    if (filter.overdueOnly) {
      // Muddati o'tgan va hali kutayotganlar. Filtr SERVERDA qo'llanadi —
      // mijozda saralansa sahifalash noto'g'ri ishlardi.
      query = query
          .eq('status', OrderStatus.pending)
          .lt('respond_by', DateTime.now().toUtc().toIso8601String());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final row in rows)
        AdminOrderRow.fromJson(Map<String, dynamic>.from(row)),
    ];
  });

  Future<Result<List<OrderHistoryEntry>>> history(String orderId) =>
      guard(() async {
        final rows = await Db.client
            .from('order_status_history')
            .select(
              'old_status, new_status, reason, changed_at, profiles(full_name)',
            )
            .eq('order_id', orderId)
            .order('changed_at', ascending: false);

        return [
          for (final r in rows)
            OrderHistoryEntry.fromJson(Map<String, dynamic>.from(r)),
        ];
      });

  /// Bitim bo'yicha baholar — nizoni tushunish uchun.
  Future<Result<List<Map<String, dynamic>>>> reviews(String orderId) =>
      guard(() async {
        final rows = await Db.client
            .from('reviews')
            .select('rating, comment, created_at')
            .eq('order_id', orderId);

        return [for (final r in rows) Map<String, dynamic>.from(r)];
      });

  /// Nizoli buyurtmani bekor qilish. Sabab majburiy.
  Future<Result<void>> cancel(String orderId, String reason) => guard(() async {
    await Db.client.rpc(
      'admin_cancel_order',
      params: {'p_order_id': orderId, 'p_reason': reason},
    );
  });
}
