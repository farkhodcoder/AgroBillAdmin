/// Murojaat holatlari (`ticket_status` enum, 0012).
abstract final class TicketStatus {
  static const open = 'open';
  static const inProgress = 'in_progress';
  static const waitingUser = 'waiting_user';
  static const resolved = 'resolved';
  static const closed = 'closed';

  static const all = <String>[open, inProgress, waitingUser, resolved, closed];

  /// Hali kimdir ishlashi kerak bo'lgan holatlar — navbat shu.
  static const active = <String>[open, inProgress, waitingUser];
}

/// Murojaat muhimligi (`ticket_priority` enum, 0012).
abstract final class TicketPriority {
  static const low = 'low';
  static const normal = 'normal';
  static const high = 'high';
  static const urgent = 'urgent';

  static const all = <String>[low, normal, high, urgent];
}

/// Murojaat (`support_tickets`, 0012).
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.assigneeName,
    this.resolution,
    this.resolvedAt,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final assignee = json['assignee'] as Map<String, dynamic>?;

    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      status: json['status'] as String? ?? TicketStatus.open,
      priority: json['priority'] as String? ?? TicketPriority.normal,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedTo: json['assigned_to'] as String?,
      assigneeName: assignee?['full_name'] as String?,
      resolution: json['resolution'] as String?,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      userName: user?['full_name'] as String?,
      userEmail: user?['email'] as String?,
      userPhone: user?['phone'] as String?,
    );
  }

  final String id;
  final String userId;
  final String category;
  final String subject;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedTo;
  final String? assigneeName;
  final String? resolution;
  final DateTime? resolvedAt;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  bool get isClosed =>
      status == TicketStatus.resolved || status == TicketStatus.closed;
}

/// Murojaatdagi xabar (`support_messages`, 0012).
///
/// [isStaff] mijozdan kelmaydi — uni baza trigger'i (`support_message_stamp`)
/// yuboruvchi `admin_users` da faolmi yo'qligiga qarab qo'yadi.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.isStaff,
    required this.content,
    required this.createdAt,
    this.senderName,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['profiles'] as Map<String, dynamic>?;
    return SupportMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      isStaff: json['is_staff'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: sender?['full_name'] as String?,
    );
  }

  final String id;
  final String senderId;
  final bool isStaff;
  final String content;
  final DateTime createdAt;
  final String? senderName;
}
