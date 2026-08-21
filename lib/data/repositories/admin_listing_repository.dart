import 'package:supabase_flutter/supabase_flutter.dart' show SignedUrlSuccess;

import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_listing.dart';

/// Bozor moderatsiyasi (TTZ §6.4).
///
/// Holat o'zgarishi FAQAT `admin_moderate_listing()` orqali (0011): u bitta
/// tranzaksiyada holatni o'zgartiradi, `listing_moderation_history` ga
/// yozadi, sotuvchiga bildirishnoma yuboradi va auditga tushadi. To'g'ridan-
/// to'g'ri `update listings` qilinsa shu to'rttadan uchtasi yo'qolardi.
class AdminListingRepository {
  static const _select =
      'id, title, status, price, unit, quantity, category, description, '
      'reject_reason, view_count, created_at, expires_at, '
      'profiles(id, full_name, email), '
      'regions(name_uz, name_ru, name_en), '
      'crop_types(name_uz, name_ru, name_en), '
      'listing_images(storage_path, sort_order)';

  Future<Result<List<AdminListingRow>>> list({
    required ListingFilter filter,
    required int page,
    String locale = 'uz',
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client
        .from('listings')
        .select(_select)
        .isFilter('deleted_at', null);

    final search = filter.search.trim();
    if (search.isNotEmpty) {
      query = query.ilike('title', '%${search.replaceAll('%', '')}%');
    }
    if (filter.status != null) query = query.eq('status', filter.status!);
    if (filter.regionId != null) {
      query = query.eq('region_id', filter.regionId!);
    }

    // Moderatsiya navbati — ESKISIDAN boshlab: eng uzoq kutgani birinchi
    // ko'rilsin (TTZ §6.4). Boshqa filtrlarda yangisidan.
    final oldestFirst = filter.status == ListingStatus.pending;

    final rows = await query
        .order('created_at', ascending: oldestFirst)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final row in rows)
        AdminListingRow.fromJson(
          Map<String, dynamic>.from(row),
          locale: locale,
        ),
    ];
  });

  /// Kutayotgan e'lonlar soni — navbat belgisida ko'rsatiladi.
  Future<Result<int>> pendingCount() => guard(() async {
    final rows = await Db.client
        .from('listings')
        .select('id')
        .eq('status', ListingStatus.pending)
        .isFilter('deleted_at', null)
        .limit(200);
    return (rows as List).length;
  });

  Future<Result<List<ModerationEntry>>> history(String listingId) =>
      guard(() async {
        final rows = await Db.client
            .from('listing_moderation_history')
            .select(
              'old_status, new_status, reason, created_at, profiles(full_name)',
            )
            .eq('listing_id', listingId)
            .order('created_at', ascending: false);

        return [
          for (final r in rows)
            ModerationEntry.fromJson(Map<String, dynamic>.from(r)),
        ];
      });

  /// Rasmlar uchun signed URL.
  ///
  /// `listing-images` buketi private; admin unga `storage_admin_read`
  /// siyosati orqali kiradi (0009) va u `listings.moderate` talab qiladi.
  /// Ruxsat bo'lmasa bo'sh ro'yxat qaytadi — moderator bo'lmagan xodim
  /// rasmlarni ko'rmaydi, lekin ekran baribir ochiladi.
  Future<Result<List<String>>> imageUrls(List<String> paths) => guard(() async {
    if (paths.isEmpty) return const <String>[];

    // `createSignedUrls` (eski) yo'q fayllarni JIMGINA tashlab ketadi —
    // natijada rasm soni kamayib, qaysi biri yo'qolgani bilinmaydi.
    // `...Result` har bir yo'l uchun muvaffaqiyat yoki xato qaytaradi.
    final results = await Db.client.storage
        .from(AdminConfig.bucketListingImages)
        .createSignedUrlsResult(paths, AdminConfig.signedUrlTtl.inSeconds);

    return [
      for (final r in results)
        if (r is SignedUrlSuccess) r.signedUrl,
    ];
  });

  /// Moderatsiya qarori.
  ///
  /// [status] — `ListingStatus.moderatable` dan biri. Salbiy qarorda sabab
  /// majburiy; baza ham tekshiradi (`REASON_REQUIRED`).
  Future<Result<void>> moderate({
    required String listingId,
    required String status,
    String? reason,
  }) => guard(() async {
    await Db.client.rpc(
      'admin_moderate_listing',
      params: {
        'p_listing_id': listingId,
        'p_new_status': status,
        'p_reason': reason,
      },
    );
  });

  /// Yumshoq o'chirish — `listings.delete` ruxsati kerak.
  Future<Result<void>> delete(String listingId, String reason) =>
      guard(() async {
        await Db.client.rpc(
          'admin_delete_listing',
          params: {'p_listing_id': listingId, 'p_reason': reason},
        );
      });
}
