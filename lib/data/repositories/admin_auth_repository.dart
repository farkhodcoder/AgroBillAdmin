import '../../core/rbac/permission.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Kirish oqimining bosqichlari.
enum AuthStage {
  /// Sessiya yo'q.
  signedOut,

  /// Sessiya bor, lekin `admin_users` da faol yozuv yo'q.
  notAdmin,

  /// To'liq tayyor.
  ready,
}

/// Admin autentifikatsiyasi va ruxsatlari.
///
/// TTZ §8 da 2FA majburiy edi, lekin loyiha egasining qarori bilan u olib
/// tashlangan (`0019_disable_mfa_requirement.sql`, 2026-08-21). `admin_has()`
/// endi `aal2` talab qilmaydi, shuning uchun bu yerda ham TOTP bosqichlari
/// yo'q: kirish oqimi `parol -> xodimlik tekshiruvi -> tayyor`.
///
/// Qaytarish uchun: migratsiyadagi `down` bloki + shu faylga
/// `needsEnrollment`/`needsVerification` bosqichlarini tiklash.
class AdminAuthRepository {
  /// Email va parol bilan kirish.
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => guard(() async {
    await Db.auth.signInWithPassword(email: email.trim(), password: password);
  });

  Future<Result<void>> signOut() => guard(() async {
    await Db.auth.signOut();
  });

  /// Joriy sessiya qaysi bosqichda ekanini aniqlaydi.
  ///
  /// Bu funksiya router uchun yagona haqiqat manbai — ekranlar o'zlari
  /// qaror qilmaydi, aks holda uch joyda uch xil mantiq paydo bo'lardi.
  Future<Result<AuthStage>> resolveStage() => guard(() async {
    if (Db.currentUser == null) return AuthStage.signedOut;

    final row = await Db.client
        .from('admin_users')
        .select('id, is_active')
        .eq('id', Db.userId!)
        .maybeSingle();

    if (row == null || row['is_active'] != true) return AuthStage.notAdmin;
    return AuthStage.ready;
  });

  /// Joriy adminning roli va ruxsatlari.
  ///
  /// `admin_role_permissions` ni `admin_users` orqali o'qiydi. Ikkalasi ham
  /// `admin.read` bilan himoyalangan, lekin `admin_users_read_own` siyosati
  /// har bir adminga O'Z qatorini beradi (0008) — shuning uchun `moderator`
  /// ham o'z ruxsatlarini yuklay oladi.
  Future<Result<AdminPermissions>> loadPermissions() => guard(() async {
    final userId = Db.userId;
    if (userId == null) return const AdminPermissions.none();

    final row = await Db.client
        .from('admin_users')
        .select('role_code, is_active, language_code')
        .eq('id', userId)
        .maybeSingle();

    if (row == null || row['is_active'] != true) {
      return const AdminPermissions.none();
    }

    final roleCode = row['role_code'] as String;
    final perms = await Db.client
        .from('admin_role_permissions')
        .select('permission_code')
        .eq('role_code', roleCode);

    return AdminPermissions(
      roleCode: roleCode,
      languageCode: row['language_code'] as String? ?? 'uz',
      codes: {for (final p in perms as List) p['permission_code'] as String},
    );
  });

  /// Kirish hodisasini yozadi (`admin_login_events`).
  ///
  /// Xatosi kirishni to'xtatmaydi: jurnal yozilmagani sababli adminni
  /// panelga kiritmaslik mantiqsiz bo'lardi.
  Future<void> recordLogin({required bool success, String? failureCode}) async {
    await guard(() async {
      await Db.client.rpc(
        'admin_record_login',
        params: {'p_success': success, 'p_failure_code': failureCode},
      );
    });
  }

  /// Interfeys tilini saqlaydi.
  ///
  /// `admin_users` da `language_code` ustuniga yozish huquqi bor
  /// (0008 dagi ustun darajasidagi grant) — qolgan ustunlar yopiq.
  Future<Result<void>> updateLanguage(String languageCode) => guard(() async {
    final userId = Db.userId;
    if (userId == null) return;
    await Db.client
        .from('admin_users')
        .update({'language_code': languageCode})
        .eq('id', userId);
  });
}
