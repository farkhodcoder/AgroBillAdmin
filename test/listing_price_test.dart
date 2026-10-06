import 'package:agrobilladminpc_web/data/models/admin_listing.dart';
import 'package:flutter_test/flutter_test.dart';

/// V2 (BOZ-04) dan beri `listings.price` NULL boʻla oladi — "kelishuv
/// asosida" eʼlon.
///
/// Bu xato JIM edi: model `_num(json['price'])` ishlatardi va u NULL ni
/// **0 ga** aylantirardi. Panel kelishiladigan eʼlonni "0" deb koʻrsatardi,
/// moderator esa uni tekin deb rad etardi. Dart tur tizimi buni ushlamadi,
/// chunki `0` ham toʻliq yaroqli `double`.
void main() {
  Map<String, dynamic> row({
    Object? price,
    String? priceMode,
    String? kind,
  }) => {
    'id': '11111111-1111-1111-1111-111111111111',
    'title': 'Sinov eʼloni',
    'status': ListingStatus.pending,
    'price': price,
    'price_mode': ?priceMode,
    'kind': ?kind,
    'quantity': 10,
    'unit': 'kg',
    'category': 'harvest',
    'created_at': '2026-10-01T00:00:00Z',
    'expires_at': '2026-11-01T00:00:00Z',
  };

  test('kelishiladigan eʼlon narxi 0 ga aylanmaydi', () {
    final listing = AdminListingRow.fromJson(
      row(price: null, priceMode: PriceMode.negotiable),
    );

    expect(listing.price, isNull);
    expect(listing.isNegotiable, isTrue);
    expect(listing.priceMode, PriceMode.negotiable);
  });

  test('qatʼiy narx oʻqiladi', () {
    final listing = AdminListingRow.fromJson(
      row(price: 12500, priceMode: PriceMode.fixed),
    );

    expect(listing.price, 12500);
    expect(listing.isNegotiable, isFalse);
  });

  test('narx matn boʻlib kelsa ham oʻqiladi', () {
    // PostgREST `numeric` ni matn qilib qaytarishi mumkin.
    final listing = AdminListingRow.fromJson(row(price: '990.5'));

    expect(listing.price, 990.5);
  });

  test('ustun soʻralmagan boʻlsa xavfsiz sukut qiymatlari', () {
    // `kind` va `price_mode` eski `select` da yoʻq edi — model yiqilmasligi
    // kerak, lekin sukut qiymati `sale`/`fixed` boʻlishi shart.
    final listing = AdminListingRow.fromJson(row(price: 100));

    expect(listing.kind, ListingKind.sale);
    expect(listing.priceMode, PriceMode.fixed);
  });

  test('ijara eʼloni turi oʻqiladi', () {
    final listing = AdminListingRow.fromJson(
      row(price: 500000, kind: ListingKind.rent),
    );

    expect(listing.kind, ListingKind.rent);
  });
}
