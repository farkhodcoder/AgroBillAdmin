import 'package:agrobilladminpc_web/data/repositories/admin_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tasdiqlash arizasi qatori — `verification_requests` + `profiles` join.
void main() {
  Map<String, dynamic> row({Map<String, dynamic>? profile}) => {
    'id': 'r1',
    'user_id': 'u1',
    'doc_type': 'farmer_certificate',
    'doc_paths': ['u1/1_0.jpg', 'u1/1_1.jpg'],
    'note': 'Urgut fermer xoʻjaligi',
    'status': 'pending',
    'created_at': '2026-10-25T10:00:00Z',
    'profiles': profile,
  };

  test('profil, aloqa va hujjatlar o\'qiladi', () {
    final r = VerificationRow.fromJson(
      row(
        profile: {
          'full_name': 'Ali Valiyev',
          'phone': '901234567',
          'email': 'ali@example.com',
          'account_type': 'buyer',
          'buyer_kind': 'exporter',
          'verified_at': null,
          'rating': 4.5,
          'rating_count': 3,
          'created_at': '2025-03-01T00:00:00Z',
        },
      ),
    );
    expect(r.isPending, isTrue);
    expect(r.docPaths, hasLength(2));
    expect(r.fullName, 'Ali Valiyev');
    // Telefon bo'lsa — telefon, emailga tushmaydi.
    expect(r.contact, '901234567');
    expect(r.accountType, 'buyer');
    expect(r.buyerKind, 'exporter');
    expect(r.isVerified, isFalse);
    expect(r.rating, 4.5);
  });

  test('telefon yo\'q bo\'lsa email ko\'rsatiladi', () {
    final r = VerificationRow.fromJson(
      row(profile: {'full_name': 'Ali', 'phone': '', 'email': 'a@b.uz'}),
    );
    expect(r.contact, 'a@b.uz');
  });

  test('profil join bo\'sh bo\'lsa ham qulamaydi', () {
    final r = VerificationRow.fromJson(row());
    expect(r.fullName, isEmpty);
    expect(r.accountType, 'farmer');
    expect(r.contact, isNull);
  });
}
