import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Chat moderatsiyasi: shikoyatlar, avto-moderatsiya jurnali va tezlik
/// cheklovlari. Hammasi `listings.moderate` ruxsati ostida (mobil 0069).
class AdminModerationRepository {
  // --- Shikoyatlar (`message_reports`, 0026) -----------------------------------

  /// `admin_message_reports` RPC (0071). To'g'ridan-to'g'ri `select` emas:
  /// shaxsiy chatdagi xabarni admin RLS orqali o'qiy olmaydi, RPC esa faqat
  /// SHIKOYAT QILINGAN bitta xabarni qaytaradi.
  Future<Result<List<MessageReport>>> reports({String? status}) =>
      guard(() async {
        final rows = await Db.client.rpc<List<dynamic>>(
          'admin_message_reports',
          params: {'p_status': status},
        );
        return [
          for (final r in rows)
            MessageReport.fromJson(Map<String, dynamic>.from(r as Map)),
        ];
      });

  /// Holat `admin_set_report_status` orqali o'zgaradi — auditga tushadi.
  Future<Result<void>> setReportStatus(
    String id,
    String status, {
    String? note,
  }) => guard(() async {
    await Db.client.rpc<void>(
      'admin_set_report_status',
      params: {'p_report': id, 'p_status': status, 'p_note': note},
    );
  });

  /// Butun suhbatni o'qish — sabab majburiy, amal auditga yoziladi
  /// (`admin_read_flagged_chat`, 0011).
  Future<Result<List<FlaggedMessage>>> readConversation(
    String conversationId,
    String reason,
  ) => guard(() async {
    final rows = await Db.client.rpc<List<dynamic>>(
      'admin_read_flagged_chat',
      params: {'p_conversation_id': conversationId, 'p_reason': reason},
    );
    return [
      for (final r in rows)
        FlaggedMessage.fromJson(Map<String, dynamic>.from(r as Map)),
    ];
  });

  // --- Avto-moderatsiya (`message_moderation`, 0049) ---------------------------

  Future<Result<List<ModerationEntry>>> moderationLog() => guard(() async {
    final rows = await Db.client
        .from('message_moderation')
        .select(
          'message_id, conversation_id, original_content, category, reason, '
          'created_at, '
          'sender:staff_profiles!message_moderation_sender_id_fkey(full_name)',
        )
        .order('created_at', ascending: false)
        .limit(100);
    return [for (final r in rows) ModerationEntry.fromJson(r)];
  });

  // --- Tezlik cheklovlari (`chat_rate_overrides`, 0027) ------------------------

  Future<Result<List<RateOverride>>> rateOverrides() => guard(() async {
    final rows = await Db.client
        .from('chat_rate_overrides')
        .select(
          'id, user_id, conversation_id, slow_mode_seconds, '
          'image_cooldown_seconds, note, updated_at, '
          'user:staff_profiles!chat_rate_overrides_user_id_fkey'
          '(full_name, email), '
          'conversations(title), '
          'editor:profiles!chat_rate_overrides_updated_by_fkey(full_name)',
        )
        .order('updated_at', ascending: false)
        .limit(200);
    return [for (final r in rows) RateOverride.fromJson(r)];
  });

  /// Hamjamiyat kanallari — cheklovni kanalga bog'lash uchun. Shaxsiy
  /// suhbatlar bu yerda chiqmaydi (RLS: ularni faqat ishtirokchi ko'radi).
  Future<Result<List<(String, String)>>> communities() => guard(() async {
    final rows = await Db.client
        .from('conversations')
        .select('id, title')
        .eq('kind', 'community')
        .order('title');
    return [
      for (final r in rows) (r['id'] as String, r['title'] as String? ?? '—'),
    ];
  });

  /// Cheklov qo'yiladigan foydalanuvchini ism, email yoki telefon bo'yicha
  /// topish (`staff_profiles` — PII faqat xodimga ochiq).
  Future<Result<List<UserPick>>> findUsers(String text) => guard(() async {
    final safe = text.trim().replaceAll(',', ' ').replaceAll('%', '');
    if (safe.length < 2) return const <UserPick>[];
    final rows = await Db.client
        .from('staff_profiles')
        .select('id, full_name, email, phone')
        .or('full_name.ilike.%$safe%,email.ilike.%$safe%,phone.ilike.%$safe%')
        .limit(8);
    return [
      for (final r in rows)
        UserPick(
          id: r['id'] as String,
          name: r['full_name'] as String?,
          contact: (r['email'] as String?) ?? (r['phone'] as String?),
        ),
    ];
  });

  /// Yangi cheklov. `0` — "chegara yo'q" (odamni butunlay ozod qiladi),
  /// `null` — bu turdagi cheklovga tegilmaydi.
  Future<Result<void>> addRateOverride({
    String? userId,
    String? conversationId,
    int? slowModeSeconds,
    int? imageCooldownSeconds,
    String? note,
  }) => guard(() async {
    await Db.client.from('chat_rate_overrides').insert({
      'user_id': userId,
      'conversation_id': conversationId,
      'slow_mode_seconds': slowModeSeconds,
      'image_cooldown_seconds': imageCooldownSeconds,
      'note': note,
      'updated_by': Db.userId,
    });
  });

  Future<Result<void>> deleteRateOverride(String id) => guard(() async {
    await Db.client.from('chat_rate_overrides').delete().eq('id', id);
  });
}

class MessageReport {
  const MessageReport({
    required this.id,
    required this.status,
    required this.reason,
    required this.createdAt,
    required this.messageId,
    required this.conversationId,
    required this.conversationKind,
    required this.content,
    required this.senderId,
    this.reporterName,
    this.senderName,
    this.conversationTitle,
    this.sentAt,
    this.hasAttachment = false,
    this.messageDeleted = false,
    this.reportCount = 1,
  });

  factory MessageReport.fromJson(Map<String, dynamic> m) => MessageReport(
    id: m['id'] as String,
    status: m['status'] as String? ?? 'open',
    reason: m['reason'] as String? ?? '',
    createdAt: DateTime.parse(m['created_at'] as String),
    reporterName: m['reporter_name'] as String?,
    messageId: m['message_id'] as String,
    conversationId: m['conversation_id'] as String,
    conversationKind: m['conversation_kind'] as String? ?? 'direct',
    conversationTitle: m['conversation_title'] as String?,
    senderId: m['sender_id'] as String,
    senderName: m['sender_name'] as String?,
    content: m['content'] as String? ?? '',
    hasAttachment: m['has_attachment'] == true,
    sentAt: m['sent_at'] == null
        ? null
        : DateTime.parse(m['sent_at'] as String),
    messageDeleted: m['message_deleted'] == true,
    reportCount: (m['report_count'] as num?)?.toInt() ?? 1,
  );

  final String id;

  /// `open` | `reviewed` | `actioned` | `dismissed`
  final String status;
  final String reason;
  final DateTime createdAt;
  final String? reporterName;

  final String messageId;
  final String conversationId;

  /// `community` | `direct` | `market`
  final String conversationKind;
  final String? conversationTitle;

  final String senderId;
  final String? senderName;
  final String content;
  final bool hasAttachment;
  final DateTime? sentAt;
  final bool messageDeleted;

  /// Shu xabarga jami nechta shikoyat tushgan.
  final int reportCount;

  bool get isOpen => status == 'open';
}

/// `admin_read_flagged_chat` qaytaradigan xabar.
class FlaggedMessage {
  const FlaggedMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isFlagged = false,
  });

  factory FlaggedMessage.fromJson(Map<String, dynamic> m) => FlaggedMessage(
    id: m['id'] as String,
    senderId: m['sender_id'] as String,
    content: m['content'] as String? ?? '',
    isFlagged: m['is_flagged'] == true,
    sentAt: DateTime.parse(m['sent_at'] as String),
  );

  final String id;
  final String senderId;
  final String content;
  final bool isFlagged;
  final DateTime sentAt;
}

/// Avtomatik to'sib qo'yilgan xabar.
class ModerationEntry {
  const ModerationEntry({
    required this.messageId,
    required this.originalContent,
    required this.category,
    required this.createdAt,
    this.reason,
    this.senderName,
  });

  factory ModerationEntry.fromJson(Map<String, dynamic> m) => ModerationEntry(
    messageId: m['message_id'] as String,
    originalContent: m['original_content'] as String? ?? '',
    category: m['category'] as String? ?? '',
    reason: m['reason'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String),
    senderName: (m['sender'] as Map?)?['full_name'] as String?,
  );

  final String messageId;
  final String originalContent;
  final String category;
  final String? reason;
  final DateTime createdAt;
  final String? senderName;
}

class RateOverride {
  const RateOverride({
    required this.id,
    required this.updatedAt,
    this.userId,
    this.conversationId,
    this.userName,
    this.userEmail,
    this.conversationTitle,
    this.slowModeSeconds,
    this.imageCooldownSeconds,
    this.note,
    this.editorName,
  });

  factory RateOverride.fromJson(Map<String, dynamic> m) {
    final user = (m['user'] as Map?)?.cast<String, dynamic>();
    return RateOverride(
      id: m['id'] as String,
      userId: m['user_id'] as String?,
      conversationId: m['conversation_id'] as String?,
      userName: user?['full_name'] as String?,
      userEmail: user?['email'] as String?,
      conversationTitle: (m['conversations'] as Map?)?['title'] as String?,
      slowModeSeconds: (m['slow_mode_seconds'] as num?)?.toInt(),
      imageCooldownSeconds: (m['image_cooldown_seconds'] as num?)?.toInt(),
      note: m['note'] as String?,
      updatedAt: DateTime.parse(m['updated_at'] as String),
      editorName: (m['editor'] as Map?)?['full_name'] as String?,
    );
  }

  final String id;

  /// `null` — kanaldagi hamma uchun.
  final String? userId;

  /// `null` — foydalanuvchining barcha suhbatlari uchun.
  final String? conversationId;
  final String? userName;
  final String? userEmail;
  final String? conversationTitle;

  /// Xabarlar orasidagi kutish (soniya). `0` — chegara yo'q.
  final int? slowModeSeconds;

  /// Rasmlar orasidagi kutish (soniya). `0` — chegara yo'q.
  final int? imageCooldownSeconds;
  final String? note;
  final DateTime updatedAt;
  final String? editorName;
}

/// Foydalanuvchi tanlash natijasi.
class UserPick {
  const UserPick({required this.id, this.name, this.contact});

  final String id;
  final String? name;
  final String? contact;

  String get label => [name ?? '—', ?contact].join(' · ');
}
