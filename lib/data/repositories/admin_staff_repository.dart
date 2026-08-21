import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_staff.dart';

/// Xodimlar, sozlamalar va kontent (TTZ §6.13, §6.15, §6.10).
///
/// Uchtasi bitta repozitoriyda: har biri kichik va bir xil manbaga
/// (`admin.write` / `settings.write` / `content.write`) tayanadi. Alohida
/// uchta fayl ochish ularni faqat bir-biridan uzoqlashtirardi.
class AdminStaffRepository {
  // --- Xodimlar ---------------------------------------------------------------

  /// `admin_users` da IKKITA ustun `profiles` ga bogʻlangan: `id` (xodimning
  /// o'zi) va `created_by` (uni kim qo'shgan). Ko'rsatgichsiz PostgREST
  /// `HTTP 300 Multiple Choices` qaytaradi — shuning uchun FK nomi aniq
  /// yoziladi.
  Future<Result<List<StaffRow>>> staff() => guard(() async {
    final rows = await Db.client
        .from('admin_users')
        .select(
          'id, role_code, is_active, language_code, last_login_at, '
          'created_at, profiles!admin_users_id_fkey(full_name, email)',
        )
        .order('created_at');

    return [
      for (final r in rows) StaffRow.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Rollar va ularning ruxsatlari — matritsa uchun.
  Future<Result<List<RoleWithPermissions>>> roles({String locale = 'uz'}) =>
      guard(() async {
        final roleRows = await Db.client
            .from('admin_roles')
            .select('code, name_uz, name_ru, name_en')
            .order('code');

        final linkRows = await Db.client
            .from('admin_role_permissions')
            .select('role_code, permission_code');

        final byRole = <String, Set<String>>{};
        for (final l in linkRows) {
          byRole
              .putIfAbsent(l['role_code'] as String, () => <String>{})
              .add(l['permission_code'] as String);
        }

        return [
          for (final r in roleRows)
            RoleWithPermissions(
              code: r['code'] as String,
              name: r['name_$locale'] as String,
              permissions: byRole[r['code']] ?? const <String>{},
            ),
        ];
      });

  /// Kirish hodisalari — kim, qachon, muvaffaqiyatlimi.
  Future<Result<List<LoginEvent>>> loginEvents({
    int limit = 50,
  }) => guard(() async {
    final rows = await Db.client
        .from('admin_login_events')
        .select(
          'id, email, success, failure_code, ip_address, '
          'user_agent, created_at',
        )
        .order('created_at', ascending: false)
        .limit(limit);

    return [
      for (final r in rows) LoginEvent.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Rolni o'zgartirish yoki xodimlikdan chiqarish.
  ///
  /// `admin_users` da rol yozish siyosati YO'Q (0008) — bu yagona yo'l.
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

  // --- Sozlamalar -------------------------------------------------------------

  Future<Result<List<AppSetting>>> settings() => guard(() async {
    final rows = await Db.client
        .from('app_settings')
        .select('key, value, description, updated_at, profiles(full_name)')
        .order('key');

    return [
      for (final r in rows) AppSetting.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Sozlamani o'zgartirish. Sabab majburiy, audit kafolatlangan (0017).
  ///
  /// [value] — `jsonb`, ya'ni son, matn yoki boolean bo'lishi mumkin.
  Future<Result<void>> updateSetting(String key, Object value, String reason) =>
      guard(() async {
        await Db.client.rpc(
          'admin_update_setting',
          params: {'p_key': key, 'p_value': value, 'p_reason': reason},
        );
      });

  // --- Kontent ----------------------------------------------------------------

  Future<Result<List<ContentRow>>> content({
    String? kind,
    String? status,
    String locale = 'uz',
  }) => guard(() async {
    var query = Db.client
        .from('content_items')
        .select(
          'id, kind, slug, status, title_uz, title_ru, title_en, '
          'body_uz, body_ru, body_en, published_at, created_at, '
          'profiles(full_name), crop_types(name_uz, name_ru, name_en)',
        );

    if (kind != null) query = query.eq('kind', kind);
    if (status != null) query = query.eq('status', status);

    final rows = await query.order('created_at', ascending: false);

    return [
      for (final r in rows)
        ContentRow.fromJson(Map<String, dynamic>.from(r), locale: locale),
    ];
  });

  /// Kontent holatini o'zgartirish.
  ///
  /// `content_items` da RPC yo'q — `content_admin_write` siyosati (0013)
  /// `for all` bo'lgani uchun to'g'ridan-to'g'ri `update` ishlaydi. Bu
  /// ataylab: kontent tahriri imtiyozli amal emas, sabab talab qilinmaydi
  /// va auditga tushmaydi.
  ///
  /// [alreadyPublished] — yozuvda `published_at` bormi. Nashr sanasi FAQAT
  /// BIRINCHI MARTA qo'yiladi: arxivdan qaytarilgan maqola "bugun nashr
  /// etilgan" bo'lib ko'rinmasligi kerak. PostgREST `update` da `coalesce`
  /// ni qo'llab-quvvatlamaydi, shuning uchun qaror chaqiruvchida.
  Future<Result<void>> setContentStatus(
    String id,
    String status, {
    required bool alreadyPublished,
  }) => guard(() async {
    await Db.client
        .from('content_items')
        .update({
          'status': status,
          if (status == 'published' && !alreadyPublished)
            'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  });
}
