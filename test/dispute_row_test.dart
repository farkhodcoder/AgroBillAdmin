import 'package:agrobilladminpc_web/data/repositories/admin_dispute_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nizo qatori — `order_disputes` + `orders` + `staff_profiles` join.
void main() {
  Map<String, dynamic> row({
    Map<String, dynamic>? opener,
    Map<String, dynamic>? order,
    String status = 'open',
  }) => {
    'id': 'd1',
    'order_id': 'be8bb51f-0000-0000-0000-000000000000',
    'reason': 'quality',
    'details': 'Mahsulot eʼlondagi suratga mos emas',
    'photos': ['u1/o1/1.jpg', 'u1/o1/2.jpg'],
    'status': status,
    'created_at': '2026-11-10T10:00:00Z',
    'opener': opener,
    'orders': order,
  };

  test('tomonlar, buyurtma va suratlar o\'qiladi', () {
    final r = DisputeRow.fromJson(
      row(
        opener: {
          'full_name': 'Ali Valiyev',
          'phone': '901234567',
          'email': 'ali@example.com',
        },
        order: {
          'status': 'in_progress',
          'quantity': 120,
          'total_price': 1800000,
          'listings': {'title': 'Pomidor'},
          'buyer': {'full_name': 'Ali Valiyev', 'phone': '901234567'},
          'seller': {'full_name': 'Vali Aliyev', 'phone': null},
        },
      ),
    );

    expect(r.isOpen, isTrue);
    expect(r.openerContact, '901234567');
    expect(r.orderShortId, 'be8bb51f');
    expect(r.listingTitle, 'Pomidor');
    expect(r.totalPrice, 1800000);
    expect(r.buyerPhone, '901234567');
    expect(r.sellerName, 'Vali Aliyev');
    expect(r.sellerPhone, isNull);
    expect(r.photos, hasLength(2));
  });

  test('telefon yo\'q bo\'lsa email ko\'rsatiladi', () {
    final r = DisputeRow.fromJson(
      row(
        opener: {'full_name': 'Ali', 'phone': '', 'email': 'ali@example.com'},
      ),
    );
    expect(r.openerContact, 'ali@example.com');
  });

  test('join bo\'sh bo\'lsa ham qulamaydi', () {
    final r = DisputeRow.fromJson(row(status: 'closed'));

    expect(r.isOpen, isFalse);
    expect(r.openerName, '');
    expect(r.openerContact, isNull);
    expect(r.listingTitle, isNull);
    expect(r.buyerName, isNull);
    expect(r.resolution, isNull);
  });
}
