import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_user.dart';

/// Foydalanuvchilar moduli (TTZ §6.2).
///
/// Barcha o'zgartirishlar RPC orqali — `admin_block_user`,
/// `admin_unblock_user`, `admin_set_role` (0010). To'g'ridan-to'g'ri
/// `update profiles` QILINMAYDI: RPC lar sababni tekshiradi va audit
/// yozuvini bir tranzaksiyada kafolatlaydi.
class AdminUserRepository {
  /// Bir sahifa foydalanuvchi.
  ///
  /// `count: exact` ishlatilmaydi — u har so'rovda butun jadvalni sanaydi.
  /// O'rniga `pageSize + 1` qator so'raladi: ortiqchasi kelsa keyingi sahifa
  /// bor demakdir.
  Future<Result<List<AdminUserRow>>> list({
    required UserFilter filter,
    required int page,
    String locale = 'uz',
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client
        .from('profiles')
        .select(
          'id, full_name, email, phone, role, activity, is_blocked, '
          'block_reason, rating, rating_count, created_at, deleted_at, '
          'regions(name_uz, name_ru, name_en), '
          'districts(name_uz, name_ru, name_en), '
          'subscriptions(plan, is_active)',
        );

    final search = filter.search.trim();
    if (search.isNotEmpty) {
      // UUID to'liq kiritilgan bo'lsa aynan shu foydalanuvchi.
      if (_uuid.hasMatch(search)) {
        query = query.eq('id', search);
      } else {
        final safe = search.replaceAll(',', ' ').replaceAll('%', '');
        query = query.or('full_name.ilike.%$safe%,email.ilike.%$safe%');
      }
    }

    if (filter.role != null) query = query.eq('role', filter.role!);
    if (filter.regionId != null) {
      query = query.eq('region_id', filter.regionId!);
    }
    if (filter.activity != null) {
      query = query.eq('activity', filter.activity!);
    }
    if (filter.blocked != null) {
      query = query.eq('is_blocked', filter.blocked!);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final row in rows)
        AdminUserRow.fromJson(Map<String, dynamic>.from(row), locale: locale),
    ];
  });

  /// Bitta foydalanuvchi.
  Future<Result<AdminUserRow>> byId(String id, {String locale = 'uz'}) =>
      guard(() async {
        final row = await Db.client
            .from('profiles')
            .select(
              'id, full_name, email, phone, role, activity, is_blocked, '
              'block_reason, rating, rating_count, created_at, deleted_at, '
              'regions(name_uz, name_ru, name_en), '
              'districts(name_uz, name_ru, name_en), '
              'subscriptions(plan, is_active)',
            )
            .eq('id', id)
            .single();

        return AdminUserRow.fromJson(
          Map<String, dynamic>.from(row),
          locale: locale,
        );
      });

  /// Viloyatlar — filtr uchun.
  Future<Result<List<RefItem>>> regions({String locale = 'uz'}) =>
      guard(() async {
        final rows = await Db.client
            .from('regions')
            .select('id, name_uz, name_ru, name_en')
            .order('name_$locale');

        return [
          for (final r in rows)
            RefItem(id: r['id'] as int, name: r['name_$locale'] as String),
        ];
      });

  Future<Result<void>> block(String userId, String reason) => guard(() async {
    await Db.client.rpc(
      'admin_block_user',
      params: {'p_user_id': userId, 'p_reason': reason},
    );
  });

  Future<Result<void>> unblock(String userId, String? reason) =>
      guard(() async {
        await Db.client.rpc(
          'admin_unblock_user',
          params: {'p_user_id': userId, 'p_reason': reason},
        );
      });

  /// Xodim roli. `roleCode` null bo'lsa xodimlikdan chiqariladi.
  Future<Result<void>> setRole(
    String userId,
    String? roleCode,
    String reason,
  ) => guard(() async {
    await Db.client.rpc(
      'admin_set_role',
      params: {
        'p_user_id': userId,
        'p_role_code': roleCode,
        'p_reason': reason,
      },
    );
  });

  /// Foydalanuvchining faoliyat lentasi (`activity_log`).
  Future<Result<List<Map<String, dynamic>>>> activity(
    String userId, {
    int limit = 50,
  }) => guard(() async {
    final rows = await Db.client
        .from('activity_log')
        .select('id, event_type, title, subtitle, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return [for (final r in rows) Map<String, dynamic>.from(r)];
  });

  /// Shu foydalanuvchi ustidagi admin amallari (`audit_log`).
  ///
  /// `audit.read` ruxsati bo'lmasa RLS bo'sh ro'yxat qaytaradi — bu xato
  /// emas, shuning uchun alohida ishlov berilmaydi.
  Future<Result<List<Map<String, dynamic>>>> auditFor(String userId) =>
      guard(() async {
        final rows = await Db.client
            .from('audit_log')
            .select('id, action, reason, actor_role, created_at')
            .eq('target_id', userId)
            .order('created_at', ascending: false)
            .limit(50);

        return [for (final r in rows) Map<String, dynamic>.from(r)];
      });

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
