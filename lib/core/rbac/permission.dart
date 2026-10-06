/// Ruxsat va rol kodlari.
///
/// Bu ro'yxat `supabase/migrations/0016_seed_rbac.sql` va `0040_founder_role.sql`
/// ning AYNAN NUSXASI. Biri o'zgarsa ikkinchisi ham o'zgarishi shart —
/// `permission_parity_test` buni tekshiradi.
///
/// MUHIM: bu yerdagi tekshiruvlar faqat UX uchun — kerak bo'lmagan menyu
/// bandini yashirish, tugmani o'chirish. HAQIQIY HIMOYA bazada:
/// `admin_has()` RLS siyosatlari va RPC lar ichida (0008–0017). Frontend ni
/// chetlab o'tish hech narsa bermaydi, chunki so'rovni server rad etadi.
library;

/// 25 ta ruxsat kodi.
abstract final class AdminPermission {
  // users
  static const usersRead = 'users.read';
  static const usersWrite = 'users.write';
  static const usersBlock = 'users.block';

  /// Akkauntni BUTUNLAY o'chirish (`admin-delete-user`).
  ///
  /// `usersWrite` dan ataylab ajratilgan: profilni tahrirlashni qaytarish
  /// mumkin, `auth.admin.deleteUser()` ni esa yo'q. 0040 ga qadar o'chirish
  /// `users.write` ga tayanardi, ya'ni ism tuzatish bilan bir darajada edi.
  static const usersDelete = 'users.delete';

  // farms
  static const farmsRead = 'farms.read';
  static const farmsWrite = 'farms.write';

  // marketplace
  static const listingsRead = 'listings.read';
  static const listingsModerate = 'listings.moderate';
  static const listingsDelete = 'listings.delete';

  // orders
  static const ordersRead = 'orders.read';
  static const ordersWrite = 'orders.write';

  // ai
  static const aiRead = 'ai.read';

  /// AI SUHBAT MATNINI o'qish — `ai.read` dan alohida, chunki bu shaxsiy
  /// yozishma. Oddiy monitoring uchun `ai.read` (faqat sonlar) yetarli.
  static const aiModerate = 'ai.moderate';

  // disease
  static const diseaseRead = 'disease.read';
  static const diseaseWrite = 'disease.write';

  // content
  static const contentRead = 'content.read';
  static const contentWrite = 'content.write';

  // notifications
  static const notificationsSend = 'notifications.send';

  // analytics
  static const analyticsRead = 'analytics.read';

  // support
  static const supportRead = 'support.read';
  static const supportWrite = 'support.write';

  // staff
  static const adminRead = 'admin.read';
  static const adminWrite = 'admin.write';

  // audit
  static const auditRead = 'audit.read';

  // settings
  static const settingsWrite = 'settings.write';

  /// Barcha kodlar — parity testi va sozlash ekrani uchun.
  static const all = <String>[
    usersRead,
    usersWrite,
    usersBlock,
    usersDelete,
    farmsRead,
    farmsWrite,
    listingsRead,
    listingsModerate,
    listingsDelete,
    ordersRead,
    ordersWrite,
    aiRead,
    aiModerate,
    diseaseRead,
    diseaseWrite,
    contentRead,
    contentWrite,
    notificationsSend,
    analyticsRead,
    supportRead,
    supportWrite,
    adminRead,
    adminWrite,
    auditRead,
    settingsWrite,
  ];
}

/// 7 ta tizim roli (`admin_roles` jadvali).
abstract final class AdminRole {
  /// Loyiha egasi — BARCHA ruxsatlarga ega.
  ///
  /// Ruxsatlari sanab o'tilmaydi: bazadagi `admin_has()` founder uchun qisqa
  /// tutashadi, shuning uchun kelajakda qo'shiladigan ruxsat ham avtomatik
  /// tegishli bo'ladi. `super_admin` bunday emas — uning ro'yxati 0016 da
  /// qotib qolgan va har bir yangi ruxsatni qo'lda berish kerak.
  static const founder = 'founder';

  static const superAdmin = 'super_admin';
  static const admin = 'admin';
  static const moderator = 'moderator';
  static const supportAgent = 'support_agent';
  static const contentManager = 'content_manager';
  static const analyst = 'analyst';

  static const all = <String>[
    founder,
    superAdmin,
    admin,
    moderator,
    supportAgent,
    contentManager,
    analyst,
  ];
}

/// Joriy adminning ruxsatlari.
///
/// `admin_users` + `admin_role_permissions` dan bir marta o'qiladi va
/// sessiya davomida saqlanadi. Rol o'zgarsa admin qayta kirishi kerak —
/// bu ataylab: ruxsat kengayishi darhol emas, ongli ravishda sodir bo'lsin.
class AdminPermissions {
  const AdminPermissions({
    required this.roleCode,
    required this.codes,
    this.languageCode = 'uz',
  });

  /// Xodim emas.
  const AdminPermissions.none()
    : roleCode = null,
      codes = const <String>{},
      languageCode = 'uz';

  final String? roleCode;
  final Set<String> codes;

  /// Interfeys tili. Qurilmada emas, `admin_users.language_code` da saqlanadi
  /// — admin boshqa kompyuterdan kirsa ham o'z tili qoladi (TTZ §9).
  final String languageCode;

  /// Loyiha egasi.
  ///
  /// Bazadagi `is_founder()` ning nusxasi. Founder uchun ruxsat ro'yxati
  /// umuman o'qilmaydi — [has] har doim `true`.
  bool get isFounder => roleCode == AdminRole.founder;

  bool get isStaff => roleCode != null && (isFounder || codes.isNotEmpty);

  /// Founder uchun har doim `true` — bazadagi `admin_has()` bilan bir xil
  /// qoida. Aks holda panel yangi ruxsatli tugmani yashirardi, server esa
  /// so'rovni qabul qilardi: egasi "nega tugma yo'q" deb qidirardi.
  bool has(String permission) => isFounder || codes.contains(permission);

  /// Berilganlardan hech bo'lmasa bittasi bormi (masalan menyu bandi bir
  /// nechta ruxsat bilan ochiladigan bo'lsa).
  bool hasAny(Iterable<String> permissions) => permissions.any(has);
}
