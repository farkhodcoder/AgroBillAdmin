import '../utils/result.dart';

/// Backend qaytaradigan xato kodlari.
///
/// TTZ §9 qoidasi: **kodlar tarjima qilinadi, matn emas.** Migratsiyalardagi
/// RPC lar (`admin_block_user`, `admin_moderate_listing`, ...) xatoni
/// `raise exception 'PERMISSION_DENIED'` ko'rinishida ko'taradi. Frontend
/// faqat shu kodni tanidi va `admin.errors.*` kalitiga xaritalaydi — server
/// matnini foydalanuvchiga hech qachon ko'rsatmaydi.
///
/// Yangi RPC yozilganda: `raise exception '<KOD>'` — va shu ro'yxatga qo'shing,
/// aks holda foydalanuvchi umumiy "server xatosi" ni ko'radi.
abstract final class AdminErrorCode {
  /// Ruxsat yo'q — `admin_has()` `false` qaytardi: foydalanuvchi
  /// `admin_users` da yo'q, `is_active` emas, yoki roliga shu ruxsat
  /// biriktirilmagan.
  static const permissionDenied = 'PERMISSION_DENIED';

  /// Sabab maydoni bo'sh yoki 5 belgidan qisqa.
  static const reasonRequired = 'REASON_REQUIRED';

  static const notFound = 'NOT_FOUND';
  static const notAuthenticated = 'NOT_AUTHENTICATED';

  /// `audit_log` ni tahrirlash/o'chirishga urinildi (0010 dagi trigger).
  static const auditImmutable = 'AUDIT_IMMUTABLE';

  /// Adminni bloklab bo'lmaydi — aks holda ikki xodim bir-birini bloklab
  /// panelni yopib qo'yishi mumkin.
  static const cannotBlockAdmin = 'CANNOT_BLOCK_ADMIN';

  /// O'z rolini o'zgartirish taqiqlangan (imtiyoz oshirish).
  static const cannotChangeOwnRole = 'CANNOT_CHANGE_OWN_ROLE';

  /// Kirish jurnaliga (`admin_login_events.failure_code`) yoziladigan kodlar.
  /// Ular baza tomonidan qaytarilmaydi — frontend yozadi, shuning uchun
  /// `_map` da yo'q.
  static const badCredentials = 'BAD_CREDENTIALS';
  static const notAdmin = 'NOT_ADMIN';

  static const invalidRole = 'INVALID_ROLE';
  static const invalidStatus = 'INVALID_STATUS';
  static const invalidValue = 'INVALID_VALUE';
  static const orderAlreadyClosed = 'ORDER_ALREADY_CLOSED';

  /// Kod -> (`FailureKind`, tarjima kaliti).
  static const _map = <String, (FailureKind, String)>{
    permissionDenied: (
      FailureKind.permission,
      'admin.errors.permission_denied',
    ),
    notAuthenticated: (FailureKind.auth, 'admin.errors.not_authenticated'),
    reasonRequired: (FailureKind.validation, 'admin.errors.reason_required'),
    notFound: (FailureKind.notFound, 'admin.errors.not_found'),
    auditImmutable: (FailureKind.permission, 'admin.errors.audit_immutable'),
    cannotBlockAdmin: (
      FailureKind.permission,
      'admin.errors.cannot_block_admin',
    ),
    cannotChangeOwnRole: (
      FailureKind.permission,
      'admin.errors.cannot_change_own_role',
    ),
    invalidRole: (FailureKind.validation, 'admin.errors.invalid_role'),
    invalidStatus: (FailureKind.validation, 'admin.errors.invalid_status'),
    invalidValue: (FailureKind.validation, 'admin.errors.invalid_value'),
    orderAlreadyClosed: (
      FailureKind.conflict,
      'admin.errors.order_already_closed',
    ),
  };

  /// Server xabaridan ma'lum kodni ajratib oladi.
  ///
  /// PostgreSQL istisno matni har doim toza kod bo'lavermaydi — PostgREST uni
  /// `'PERMISSION_DENIED'` yoki qo'shimcha kontekst bilan qaytarishi mumkin,
  /// shuning uchun to'liq tenglik emas, ichida borligi tekshiriladi.
  /// Kodlar `SCREAMING_SNAKE_CASE` va o'zaro prefiks emas, shuning uchun
  /// noto'g'ri moslik xavfi yo'q.
  static AppFailure? failureFrom(String? message) {
    if (message == null || message.isEmpty) return null;
    for (final entry in _map.entries) {
      if (message.contains(entry.key)) {
        final (kind, key) = entry.value;
        return AppFailure(kind, key, detail: message);
      }
    }
    return null;
  }
}
