import 'dart:math' as math;

import 'package:agrobilladminpc_web/ui/agro_mark.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brend belgisidagi barg to'g'ri yo'nalganini tekshiradi.
///
/// NEGA KERAK: chizma `CustomPainter` orqali hosil bo'ladi, ya'ni uni
/// kod o'qib tasavvur qilish qiyin va yo'nalishni adashtirish oson —
/// doira markazlarining ishorasini almashtirish bargni teskari buradi va
/// u brauzer yorlig'idagi PNG ikonkaga mos kelmay qoladi. Bu yerda nuqta
/// bargning ichidami yoki tashqarisidami, aniq tekshiriladi.
///
/// Shakl `tool/make_icons.js` dagi PNG bilan bir xil bo'lishi shart.
void main() {
  const side = 192.0;
  const c = side / 2;

  Offset along(Offset direction, double distance) =>
      Offset(c, c) + direction * (distance / direction.distance);

  test('barg pastdan-chapdan yuqoriga-oʻngga choʻzilgan', () {
    final leaf = AgroMark.leafPath(side);

    // Ekran koordinatalarida y pastga qarab o'sadi, shuning uchun
    // (1, -1) — o'ngga va YUQORIGA, ya'ni bargning uchi.
    const axis = Offset(1, -1);
    const across = Offset(1, 1);

    expect(leaf.contains(const Offset(c, c)), isTrue, reason: 'markaz ichida');

    // Uzun o'q bo'ylab uzoq nuqta — hali ham barg ichida.
    expect(
      leaf.contains(along(axis, 0.55 * c)),
      isTrue,
      reason: 'uzun oʻq boʻylab nuqta bargdan tashqarida — barg juda kalta',
    );
    expect(
      leaf.contains(along(-axis, 0.55 * c)),
      isTrue,
      reason: 'qarama-qarshi uch topilmadi — barg nosimmetrik',
    );

    // AYNI masofada, lekin ko'ndalang yo'nalishda — tashqarida bo'lishi
    // shart. Aks holda shakl barg emas, doira bo'lardi.
    expect(
      leaf.contains(along(across, 0.55 * c)),
      isFalse,
      reason: 'koʻndalang nuqta ham ichida — shakl barg emas, doira',
    );
    expect(
      leaf.contains(along(-across, 0.55 * c)),
      isFalse,
      reason: 'koʻndalang nuqta ham ichida — shakl barg emas, doira',
    );
  });

  test('barg ramkadan chiqib ketmaydi', () {
    final b = AgroMark.leafPath(side).getBounds();
    expect(b.left, greaterThanOrEqualTo(0));
    expect(b.top, greaterThanOrEqualTo(0));
    expect(b.right, lessThanOrEqualTo(side));
    expect(b.bottom, lessThanOrEqualTo(side));

    // Barg uzunligi = chegara toʻrtburchagining diagonali (uchlari qarama-
    // qarshi burchaklarda). Dizayn boʻyicha u tomonning ~76% i: barg
    // ikonkani toʻldiradi, lekin burchaklarga tegmaydi. Chegaralar keng —
    // barg qisqarib qolsa yoki ramkaga tiqilsa test aytadi, lekin kichik
    // moslashtirishlardan yiqilmaydi.
    final length = math.sqrt(b.width * b.width + b.height * b.height);
    expect(length, greaterThan(side * 0.7), reason: 'barg juda kichik');
    expect(length, lessThan(side * 0.85), reason: 'barg ramkaga tiqilgan');
  });
}
