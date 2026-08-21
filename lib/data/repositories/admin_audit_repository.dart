import 'dart:convert';

import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Audit jurnali yozuvi.
class AuditRow {
  const AuditRow({
    required this.id,
    required this.scope,
    required this.action,
    required this.createdAt,
    this.actorName,
    this.actorEmail,
    this.actorRole,
    this.targetType,
    this.targetId,
    this.reason,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    this.userAgent,
  });

  factory AuditRow.fromJson(Map<String, dynamic> json) {
    final actor = json['profiles'] as Map<String, dynamic>?;
    return AuditRow(
      id: json['id'] as String,
      scope: json['scope'] as String? ?? '',
      action: json['action'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      actorName: actor?['full_name'] as String?,
      actorEmail: actor?['email'] as String?,
      actorRole: json['actor_role'] as String?,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      reason: json['reason'] as String?,
      oldValue: json['old_value'] as Map<String, dynamic>?,
      newValue: json['new_value'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }

  final String id;
  final String scope;
  final String action;
  final DateTime createdAt;
  final String? actorName;
  final String? actorEmail;
  final String? actorRole;
  final String? targetType;
  final String? targetId;
  final String? reason;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? ipAddress;
  final String? userAgent;

  /// O'zgargan maydonlar — `old_value` va `new_value` farqi.
  ///
  /// `old_value` odatda BUTUN qatorni saqlaydi (`to_jsonb(p)`), `new_value`
  /// esa faqat o'zgarganini. Ikkalasini yonma-yon ko'rsatish o'nlab
  /// tegilmagan maydonni ham chiqarardi, shuning uchun `new_value` dagi
  /// kalitlar bo'yicha yuriladi.
  List<(String field, String? before, String? after)> get changes {
    final next = newValue;
    if (next == null) return const [];

    final result = <(String, String?, String?)>[];
    next.forEach((key, value) {
      final before = oldValue?[key];
      result.add((key, _render(before), _render(value)));
    });
    return result;
  }

  static String? _render(Object? v) => switch (v) {
    null => null,
    String s => s,
    Map() || List() => jsonEncode(v),
    _ => v.toString(),
  };
}

class AuditFilter {
  const AuditFilter({this.action, this.targetType, this.actorId});

  final String? action;
  final String? targetType;
  final String? actorId;

  AuditFilter copyWith({
    String? action,
    String? targetType,
    String? actorId,
    bool clearAction = false,
    bool clearTargetType = false,
    bool clearActor = false,
  }) => AuditFilter(
    action: clearAction ? null : (action ?? this.action),
    targetType: clearTargetType ? null : (targetType ?? this.targetType),
    actorId: clearActor ? null : (actorId ?? this.actorId),
  );

  bool get isEmpty => action == null && targetType == null && actorId == null;
}

/// Audit jurnali (TTZ §6.14) — FAQAT O'QISH.
///
/// Yozuv 0010 dagi triggerlar bilan o'zgarmas qilingan: `update` va
/// `delete` `AUDIT_IMMUTABLE` bilan rad etiladi. Shuning uchun bu
/// repozitoriyda yozish metodi umuman yo'q.
class AdminAuditRepository {
  Future<Result<List<AuditRow>>> list({
    required AuditFilter filter,
    required int page,
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client
        .from('audit_log')
        .select(
          'id, scope, action, target_type, target_id, reason, actor_role, '
          'old_value, new_value, ip_address, user_agent, created_at, '
          'profiles(full_name, email)',
        )
        .eq('scope', 'admin');

    if (filter.action != null) query = query.eq('action', filter.action!);
    if (filter.targetType != null) {
      query = query.eq('target_type', filter.targetType!);
    }
    if (filter.actorId != null) query = query.eq('user_id', filter.actorId!);

    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final r in rows) AuditRow.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Jurnalda uchraydigan amallar — filtr ro'yxati uchun.
  ///
  /// Qat'iy ro'yxat yozilmadi: yangi RPC qo'shilganda filtr eskirib
  /// qolardi va admin uni ko'rmay qolardi.
  Future<Result<List<String>>> actions({int sample = 500}) => guard(() async {
    final rows = await Db.client
        .from('audit_log')
        .select('action')
        .eq('scope', 'admin')
        .order('created_at', ascending: false)
        .limit(sample);

    final set = <String>{for (final r in rows) r['action'] as String};
    final list = set.toList()..sort();
    return list;
  });
}
