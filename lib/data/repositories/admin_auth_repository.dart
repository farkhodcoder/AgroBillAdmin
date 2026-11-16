import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/rbac/permission.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Kirish oqimining bosqichlari.
enum AuthStage {
  /// Sessiya yo'q.
  signedOut,

  /// Sessiya bor, lekin `admin_users` da faol yozuv yo'q.
  notAdmin,

  /// 2FA majburiy, lekin xodim hali ulamagan — QR ekrani.
  mfaEnroll,

  /// 2FA ulangan, shu sessiyada kod hali kiritilmagan.
  mfaVerify,

  /// To'liq tayyor.
  ready,
}

/// `admin-login-guard` javobi.
class LoginGuardVerdict {
  const LoginGuardVerdict({required this.locked, required this.retryAfter});

  final bool locked;

  /// Blok tugashigacha qolgan vaqt.
  final Duration retryAfter;
}

/// Yangi TOTP omili — hali tasdiqlanmagan.
class MfaEnrollment {
  const MfaEnrollment({
    required this.factorId,
    required this.secret,
    required this.qrSvg,
  });

  final String factorId;

  /// QR skanerlab bo'lmasa qo'lda kiritiladigan kalit.
  final String secret;

  /// QR kod — xom SVG matni (`<svg ...>`).
  final String qrSvg;
}

/// Admin autentifikatsiyasi va ruxsatlari.
///
/// Kirish oqimi (TTZ §8): `parol -> xodimlik tekshiruvi -> 2FA -> tayyor`.
///
/// 2FA `0019` da olib tashlangan edi, `0067` uni QAYTARDI, lekin bayroq bilan:
/// `app_settings.admin.mfa_required`. Bayroq `false` bo'lsa ham 2FA ni
/// ulagan xodimdan har kirishda kod so'raladi — ulagan odam himoyani kutadi.
/// Server tomoni: bayroq yoqilganda `admin_has()` faqat `aal2` sessiyada
/// `true` qaytaradi, ya'ni bu ekranlarni chetlab o'tish foyda bermaydi.
class AdminAuthRepository {
  static const mfaRequiredKey = 'admin.mfa_required';

  /// Bosqichni aniqlaydigan SOF mantiq — tarmoqsiz, test bilan qoplangan.
  static AuthStage stageFor({
    required bool isStaff,
    required bool mfaRequired,
    required bool sessionIsAal2,
    required bool hasVerifiedFactor,
  }) {
    if (!isStaff) return AuthStage.notAdmin;
    if (sessionIsAal2) return AuthStage.ready;
    if (hasVerifiedFactor) return AuthStage.mfaVerify;
    if (mfaRequired) return AuthStage.mfaEnroll;
    return AuthStage.ready;
  }

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

    // `admin_users_read_own` siyosati `admin_has()` ga bog'liq emas — xodim
    // 2FA dan o'tmagan sessiyada ham O'Z qatorini o'qiy oladi.
    final row = await Db.client
        .from('admin_users')
        .select('id, is_active')
        .eq('id', Db.userId!)
        .maybeSingle();

    final isStaff = row != null && row['is_active'] == true;
    if (!isStaff) return AuthStage.notAdmin;

    // Kalit yo'q bo'lsa (0067 hali qo'llanmagan) — majburiy emas.
    final setting = await Db.client
        .from('app_settings')
        .select('value')
        .eq('key', mfaRequiredKey)
        .maybeSingle();

    final aal = Db.auth.mfa.getAuthenticatorAssuranceLevel();

    return stageFor(
      isStaff: true,
      mfaRequired: setting?['value'] == true,
      sessionIsAal2: aal.currentLevel == AuthenticatorAssuranceLevels.aal2,
      hasVerifiedFactor: hasTotp,
    );
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

  // --- 2FA (TOTP) --------------------------------------------------------------

  /// Tasdiqlangan TOTP omili bormi (sessiyadagi foydalanuvchi ma'lumotidan).
  bool get hasTotp => _verifiedTotp != null;

  Factor? get _verifiedTotp {
    for (final f in Db.currentUser?.factors ?? const <Factor>[]) {
      if (f.factorType == FactorType.totp &&
          f.status == FactorStatus.verified) {
        return f;
      }
    }
    return null;
  }

  /// Yangi TOTP omilini boshlaydi va QR ni qaytaradi.
  ///
  /// Avval yarim qolgan (tasdiqlanmagan) omillar tozalanadi: sahifa
  /// yangilansa yoki admin ekranni yopib qayta ochsa, eski urinish qolib
  /// ketadi va Supabase "bunday nomli omil bor" deb yangisini rad etadi.
  Future<Result<MfaEnrollment>> startMfaEnrollment() => guard(() async {
    final factors = await Db.auth.mfa.listFactors();
    for (final f in factors.all) {
      if (f.factorType == FactorType.totp &&
          f.status != FactorStatus.verified) {
        await Db.auth.mfa.unenroll(f.id);
      }
    }

    final res = await Db.auth.mfa.enroll(
      issuer: 'AgroBill Admin',
      friendlyName: 'admin-${DateTime.now().millisecondsSinceEpoch}',
    );
    final totp = res.totp;
    if (totp == null) throw StateError('TOTP maʼlumoti qaytmadi');

    return MfaEnrollment(
      factorId: res.id,
      secret: totp.secret,
      qrSvg: svgFromQr(totp.qrCode),
    );
  });

  /// Supabase QR ni `data:image/svg+xml;utf-8,<svg ...>` ko'rinishida
  /// qaytaradi; `SvgPicture.string` ga faqat `<svg` dan boshlab kerak.
  static String svgFromQr(String qrCode) {
    final start = qrCode.indexOf('<svg');
    return start <= 0 ? qrCode : qrCode.substring(start);
  }

  /// Yangi omilni authenticator ilovasidagi kod bilan tasdiqlaydi.
  /// Muvaffaqiyatli bo'lsa sessiya `aal2` ga ko'tariladi.
  Future<Result<void>> confirmMfaEnrollment({
    required String factorId,
    required String code,
  }) => guard(() async {
    await Db.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
  });

  /// Kirishdagi ikkinchi bosqich.
  Future<Result<void>> verifyMfa(String code) => guard(() async {
    final factor = _verifiedTotp;
    if (factor == null) throw StateError('TOTP omili topilmadi');
    await Db.auth.mfa.challengeAndVerify(factorId: factor.id, code: code);
  });

  // --- Parol -------------------------------------------------------------------

  /// O'z parolini almashtirish.
  ///
  /// Sessiya o'g'irlangan bo'lsa parolni jimgina almashtirib bo'lmasligi
  /// kerak, shuning uchun shaxs qayta tasdiqlanadi:
  ///   * 2FA ulangan  -> authenticator kodi ([totpCode]). Parol bilan qayta
  ///     kirish bu yerda YARAMAYDI: u sessiyani `aal1` ga tushiradi, Supabase
  ///     esa 2FA ulangan akkauntda parolni faqat `aal2` da almashtiradi.
  ///   * 2FA yo'q     -> joriy parol ([currentPassword]).
  Future<Result<void>> changePassword({
    required String newPassword,
    String? currentPassword,
    String? totpCode,
  }) => guard(() async {
    final factor = _verifiedTotp;
    if (factor != null) {
      await Db.auth.mfa.challengeAndVerify(
        factorId: factor.id,
        code: totpCode ?? '',
      );
    } else {
      final email = Db.currentUser?.email;
      if (email == null) throw const AuthException('Sessiya yoʻq');
      await Db.auth.signInWithPassword(
        email: email,
        password: currentPassword ?? '',
      );
    }
    await Db.auth.updateUser(UserAttributes(password: newPassword));
  });

  // --- Kirish jurnali ----------------------------------------------------------

  /// `admin-login-guard` ga murojaat: [action] — `check` yoki `fail`.
  ///
  /// `null` — funksiya javob bermadi (deploy qilinmagan, tarmoq). Bu holda
  /// kirish TO'XTATILMAYDI: yordamchi himoya ishlamagani uchun adminni
  /// panelga kiritmaslik mantiqsiz. Asosiy to'siq — parol va 2FA.
  Future<LoginGuardVerdict?> loginGuard(String action, String email) async {
    try {
      final res = await Db.client.functions
          .invoke(
            'admin-login-guard',
            body: {'action': action, 'email': email.trim()},
          )
          .timeout(const Duration(seconds: 6));
      final data = res.data;
      if (data is! Map) return null;
      return LoginGuardVerdict(
        locked: data['locked'] == true,
        retryAfter: Duration(
          seconds: (data['retry_after'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (_) {
      return null;
    }
  }

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
