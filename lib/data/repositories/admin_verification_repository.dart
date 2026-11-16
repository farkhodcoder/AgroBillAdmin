import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Profilni hujjat orqali tasdiqlash navbati (mobil ilova 0051 migratsiyasi).
///
/// Foydalanuvchi ilovada hujjat suratini yuklaydi. Admin shu yerda ko'radi
/// va tasdiqlaydi yoki sabab bilan rad etadi. Tasdiqlansa bozorda
/// "Tasdiqlangan" belgisi chiqadi.
class AdminVerificationRepository {
  Future<Result<List<VerificationRow>>> list({String? status}) =>
      guard(() async {
        var query = Db.client
            .from('verification_requests')
            .select(
              'id, user_id, doc_type, doc_paths, note, status, reject_reason, '
              'created_at, reviewed_at, '
              'profiles:staff_profiles!verification_requests_user_id_fkey'
              '(full_name, phone, email, account_type, buyer_kind, '
              'verified_at, rating, rating_count, created_at)',
            );
        if (status != null) query = query.eq('status', status);

        final rows = await query
            .order('created_at', ascending: status != 'pending')
            .limit(AdminConfig.pageSize);
        return [for (final r in rows) VerificationRow.fromJson(r)];
      });

  /// Hujjat suratlari — `verification-docs` buketi private, `users.read`
  /// huquqli xodim signed URL oladi.
  Future<Result<List<String>>> docUrls(List<String> paths) => guard(() async {
    if (paths.isEmpty) return const <String>[];
    final results = await Db.client.storage
        .from(AdminConfig.bucketVerificationDocs)
        .createSignedUrlsResult(paths, AdminConfig.signedUrlTtl.inSeconds);
    return [
      for (final r in results)
        if (r is SignedUrlSuccess) r.signedUrl,
    ];
  });

  /// `review_verification` RPC `users.write` ni serverda tekshiradi va
  /// rad etishda sababni majburiy qiladi.
  Future<Result<void>> review(
    String id, {
    required bool approve,
    String? reason,
  }) => guard(() async {
    await Db.client.rpc<void>(
      'review_verification',
      params: {'p_id': id, 'p_approve': approve, 'p_reason': reason},
    );
  });

  /// Belgini olib tashlash — masalan, soxta hujjat keyin aniqlansa.
  Future<Result<void>> revoke(String userId, String reason) => guard(() async {
    await Db.client.rpc<void>(
      'revoke_verification',
      params: {'p_user': userId, 'p_reason': reason},
    );
  });
}

class VerificationRow {
  const VerificationRow({
    required this.id,
    required this.userId,
    required this.docType,
    required this.docPaths,
    required this.status,
    required this.createdAt,
    required this.fullName,
    required this.accountType,
    this.note,
    this.rejectReason,
    this.reviewedAt,
    this.contact,
    this.buyerKind,
    this.isVerified = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.joinedAt,
  });

  factory VerificationRow.fromJson(Map<String, dynamic> m) {
    final p = (m['profiles'] as Map?)?.cast<String, dynamic>() ?? const {};
    final phone = p['phone'] as String?;
    return VerificationRow(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      docType: m['doc_type'] as String? ?? 'other',
      docPaths: [for (final x in (m['doc_paths'] as List? ?? const [])) '$x'],
      status: m['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(m['created_at'] as String),
      note: m['note'] as String?,
      rejectReason: m['reject_reason'] as String?,
      reviewedAt: m['reviewed_at'] == null
          ? null
          : DateTime.parse(m['reviewed_at'] as String),
      fullName: p['full_name'] as String? ?? '',
      contact: (phone == null || phone.isEmpty) ? p['email'] as String? : phone,
      accountType: p['account_type'] as String? ?? 'farmer',
      buyerKind: p['buyer_kind'] as String?,
      isVerified: p['verified_at'] != null,
      rating: (p['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (p['rating_count'] as num?)?.toInt() ?? 0,
      joinedAt: p['created_at'] == null
          ? null
          : DateTime.parse(p['created_at'] as String),
    );
  }

  final String id;
  final String userId;

  /// `passport` | `farmer_certificate` | `company_certificate` | `other`
  final String docType;
  final List<String> docPaths;

  /// `pending` | `approved` | `rejected`
  final String status;
  final DateTime createdAt;
  final String? note;
  final String? rejectReason;
  final DateTime? reviewedAt;

  final String fullName;
  final String? contact;

  /// `farmer` | `buyer`
  final String accountType;
  final String? buyerKind;

  /// Profil hozir tasdiqlanganmi (ariza holatidan qat'i nazar).
  final bool isVerified;
  final double rating;
  final int ratingCount;
  final DateTime? joinedAt;

  bool get isPending => status == 'pending';
}
