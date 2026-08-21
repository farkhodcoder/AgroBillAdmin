/// Admin panelining Supabase ulanish sozlamalari.
///
/// Mobil ilovadagi `supabase_config.dart` ning qisqartirilgan nusxasi: Google
/// Sign-In va AI provayder kalitlari bu yerda kerak emas.
///
/// `publishable` kalit dizayni bo'yicha OCHIQ: u har bir mijoz ilovasida
/// bo'ladi va ma'lumotni RLS himoya qiladi, kalit emas. `service_role` kaliti
/// esa RLS ni butunlay chetlab o'tadi — u HECH QACHON bu loyihaga
/// qo'yilmaydi, hatto `--dart-define` orqali ham. Uni talab qiladigan
/// amallar (majburiy chiqarish, akkauntni o'chirish, kampaniya yuborish)
/// Edge Function ichida bajariladi (TTZ §5.9).
///
/// Ishga tushirish:
/// ```
/// flutter run -d chrome \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
/// ```
library;

abstract final class AdminConfig {
  /// Loyiha URL manzili.
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qcpbholuttgmfojmpoct.supabase.co',
  );

  /// Yangi format (`sb_publishable_...`) — eski `anon` JWT ning o'rnini
  /// bosadi. Ikkalasi ham ochiq kalit.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ouSLSUWU8RM_a50kUeWSIQ_v2F67CQO',
  );

  /// Eski loyihalar uchun zaxira.
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// SDK ga uzatiladigan kalit.
  static String get clientKey =>
      publishableKey.isNotEmpty ? publishableKey : anonKey;

  /// Kalitlar berilmagan bo'lsa panel ochiladi, lekin har qanday so'rov
  /// tushunarli xato qaytaradi — shunda dizayn tizimini kalitsiz ham
  /// ko'rish mumkin va "null" bilan qulab tushmaydi.
  static bool get isConfigured => url.isNotEmpty && clientKey.isNotEmpty;

  /// Adminga ochiq storage buketlari (0009_admin_rls.sql).
  /// `avatars` va `field-photos` ATAYLAB yo'q — moderatsiya uchun kerak emas.
  static const bucketScanImages = 'scan-images';
  static const bucketListingImages = 'listing-images';

  /// Signed URL amal qilish muddati.
  static const signedUrlTtl = Duration(hours: 1);

  /// Ro'yxatlarda bir sahifadagi qatorlar soni.
  static const pageSize = 50;
}
