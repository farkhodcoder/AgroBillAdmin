import 'package:agrobilladminpc_web/data/repositories/admin_moderation_repository.dart';
import 'package:agrobilladminpc_web/data/repositories/admin_request_repository.dart';
import 'package:agrobilladminpc_web/features/moderation/pages/chat_moderation_page.dart';
import 'package:agrobilladminpc_web/features/staff/pages/staff_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeletionRequest', () {
    final row = DeletionRequest.fromJson({
      'id': 'd1',
      'user_id': 'u1',
      'requested_at': '2026-11-01T10:00:00Z',
      'scheduled_deletion_at': '2026-11-15T10:00:00Z',
      'status': 'pending',
      'profiles': {'full_name': 'Ali', 'email': 'a@x.uz', 'phone': '  '},
    });

    test('bo\'sh telefon o\'rniga email ko\'rsatiladi', () {
      expect(row.fullName, 'Ali');
      expect(row.contact, 'a@x.uz');
      expect(row.isPending, isTrue);
    });

    test('qolgan kunlar manfiy bo\'lmaydi', () {
      expect(row.daysLeft(DateTime.utc(2026, 11, 5, 10)), 10);
      expect(row.daysLeft(DateTime.utc(2026, 12, 1)), 0);
    });

    test('profil yo\'q bo\'lsa ham yiqilmaydi', () {
      final r = DeletionRequest.fromJson({
        'id': 'd2',
        'user_id': 'u2',
        'requested_at': '2026-11-01T10:00:00Z',
        'scheduled_deletion_at': '2026-11-15T10:00:00Z',
        'status': 'completed',
        'profiles': null,
      });
      expect(r.fullName, isNull);
      expect(r.contact, isNull);
    });
  });

  test('MarketRequest: takliflar arzonidan boshlab, region tilga mos', () {
    final r = MarketRequest.fromJson({
      'id': 'r1',
      'title': 'Pomidor',
      'category': 'vegetable',
      'quantity': 2,
      'unit': 't',
      'status': 'open',
      'created_at': '2026-11-01T10:00:00Z',
      'buyer': {'full_name': 'Vali', 'phone': '+998'},
      'regions': {'name_uz': 'Toshkent', 'name_ru': 'Ташкент'},
      'offers': [
        {
          'id': 'o1',
          'price': 5000,
          'quantity': 1,
          'status': 'pending',
          'created_at': '2026-11-02T10:00:00Z',
        },
        {
          'id': 'o2',
          'price': 4200,
          'quantity': 2,
          'status': 'accepted',
          'created_at': '2026-11-02T11:00:00Z',
          'farmer': {'full_name': 'Fermer'},
        },
      ],
    }, locale: 'ru');

    expect(r.quantity, 2.0);
    expect(r.buyerName, 'Vali');
    expect(r.regionName, 'Ташкент');
    expect([for (final o in r.offers) o.id], ['o2', 'o1']);
    expect(r.offers.first.farmerName, 'Fermer');
  });

  test('MessageReport.fromJson', () {
    final r = MessageReport.fromJson({
      'id': 'p1',
      'status': 'open',
      'reason': 'spam',
      'created_at': '2026-11-01T10:00:00Z',
      'message_id': 'm1',
      'conversation_id': 'c1',
      'conversation_kind': 'direct',
      'sender_id': 's1',
      'content': 'salom',
      'has_attachment': true,
      'sent_at': null,
      'message_deleted': false,
      'report_count': 3,
    });
    expect(r.isOpen, isTrue);
    expect(r.messageId, 'm1');
    expect(r.hasAttachment, isTrue);
    expect(r.sentAt, isNull);
    expect(r.reportCount, 3);
  });

  test('parseLimit: bo\'sh — null, chegaradan tashqari — -1', () {
    expect(parseLimit(''), isNull);
    expect(parseLimit(' 0 '), 0);
    expect(parseLimit('30'), 30);
    expect(parseLimit('86400'), 86400);
    expect(parseLimit('86401'), -1);
    expect(parseLimit('abc'), -1);
  });

  test('UserPick.label', () {
    expect(
      const UserPick(id: '1', name: 'Ali', contact: 'a@x').label,
      'Ali · a@x',
    );
    expect(const UserPick(id: '1').label, '—');
  });

  test('xodim paroli: har turdan kamida bittasi bor', () {
    for (var i = 0; i < 500; i++) {
      final p = generateStaffPassword();
      expect(p.length, 14);
      expect(p, matches(RegExp('[A-Z]')));
      expect(p, matches(RegExp('[a-z]')));
      expect(p, matches(RegExp('[0-9]')));
      expect(p, matches(RegExp(r'[!@#%*?]')));
    }
  });
}
