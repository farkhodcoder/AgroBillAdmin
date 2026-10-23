import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_support.dart';

/// Qo'llab-quvvatlash — murojaatlar navbati va yozishma (TTZ §6.12).
///
/// RPC yo'q: 0012 dagi siyosatlar yetarli. `tickets_admin_write` faqat
/// UPDATE ga ruxsat beradi (`support.write`), xabar esa
/// `support_messages_send` orqali yuboriladi va `is_staff` ni baza o'zi
/// qo'yadi — mijoz uni soxtalashtira olmaydi.
class AdminSupportRepository {
  /// `support_tickets` da IKKITA ustun `profiles` ga bog'langan (`user_id`,
  /// `assigned_to`) — FK nomi ko'rsatilmasa PostgREST `300 Multiple Choices`
  /// qaytaradi. Taxallus (`user:`, `assignee:`) modelda o'qishni soddalashtiradi.
  static const _ticketSelect =
      'id, user_id, category, subject, status, priority, assigned_to, '
      'resolution, resolved_at, created_at, updated_at, '
      'user:profiles!support_tickets_user_id_fkey(full_name, email, phone), '
      'assignee:profiles!support_tickets_assigned_to_fkey(full_name)';

  /// Murojaatlar navbati.
  ///
  /// Holat tanlanmasa faqat FAOL murojaatlar (ochiq, ishlanmoqda, javob
  /// kutilmoqda) — yopilganlar navbatni ko'mib yubormasin. Saralash: eng
  /// muhimi tepada, bir xil muhimlikda eskisi birinchi (FIFO).
  Future<Result<List<SupportTicket>>> tickets({
    required int page,
    String? status,
    String? priority,
    String? assignedTo,
    String search = '',
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client.from('support_tickets').select(_ticketSelect);

    if (status != null) {
      query = query.eq('status', status);
    } else {
      query = query.inFilter('status', TicketStatus.active);
    }
    if (priority != null) query = query.eq('priority', priority);
    if (assignedTo != null) query = query.eq('assigned_to', assignedTo);

    final q = search.trim().replaceAll('%', '').replaceAll(',', ' ');
    if (q.isNotEmpty) query = query.ilike('subject', '%$q%');

    // `ticket_priority` enum tartibi: low < normal < high < urgent.
    final rows = await query
        .order('priority', ascending: false)
        .order('created_at')
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final r in rows)
        SupportTicket.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Holatlar bo'yicha son — sahifa tepasidagi kartalar.
  ///
  /// `count: exact` har holat uchun alohida, lekin faqat `head` so'rov:
  /// qatorlarning o'zi yuklanmaydi.
  Future<Result<Map<String, int>>> statusCounts() => guard(() async {
    final entries = await Future.wait([
      for (final s in TicketStatus.all)
        Db.client
            .from('support_tickets')
            .select('id')
            .eq('status', s)
            .limit(1)
            .count(CountOption.exact)
            .then((res) => MapEntry(s, res.count)),
    ]);
    return Map.fromEntries(entries);
  });

  Future<Result<List<SupportMessage>>> messages(String ticketId) =>
      guard(() async {
        final rows = await Db.client
            .from('support_messages')
            .select(
              'id, sender_id, is_staff, content, created_at, '
              'profiles(full_name)',
            )
            .eq('ticket_id', ticketId)
            .order('created_at');

        return [
          for (final r in rows)
            SupportMessage.fromJson(Map<String, dynamic>.from(r)),
        ];
      });

  /// Xodim javobi. Holatni trigger o'zi yangilaydi: `open` bo'lsa
  /// `in_progress` ga o'tadi (0012).
  Future<Result<void>> reply(String ticketId, String content) =>
      guard(() async {
        await Db.client.from('support_messages').insert({
          'ticket_id': ticketId,
          'sender_id': Db.userId,
          'content': content.trim(),
        });
      });

  /// Holat, muhimlik, mas'ul yoki yechim.
  ///
  /// `resolved_at` faqat hal qilinganda qo'yiladi va qayta ochilganda
  /// tozalanadi — "qancha vaqtda hal qilindi" hisobi to'g'ri qolsin.
  Future<Result<void>> update(
    String ticketId, {
    String? status,
    String? priority,
    String? assignedTo,
    bool unassign = false,
    String? resolution,
  }) => guard(() async {
    await Db.client
        .from('support_tickets')
        .update({
          'status': ?status,
          'priority': ?priority,
          if (assignedTo != null || unassign) 'assigned_to': assignedTo,
          'resolution': ?resolution,
          if (status == TicketStatus.resolved)
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          if (status != null && TicketStatus.active.contains(status))
            'resolved_at': null,
        })
        .eq('id', ticketId);
  });
}
