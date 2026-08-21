import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TTZ §9: uchala tildagi kalitlar toʻplami AYNAN BIR XIL boʻlishi shart.
///
/// Yetishmagan kalit runtime'da xatoga olib kelmaydi — `easy_localization`
/// oddiygina RAW KALITNI ekranga chiqaradi (`admin.errors.not_found`). Bu
/// faqat oʻsha til tanlanganda koʻrinadi, ya'ni odatda releasedan keyin.
/// Shuning uchun tekshiruv build vaqtida bajariladi.
void main() {
  const locales = ['uz', 'ru', 'en'];

  late final Map<String, Set<String>> keysByLocale;

  setUpAll(() {
    keysByLocale = {
      for (final locale in locales)
        locale: _flatten(
          jsonDecode(
                File('assets/translations/$locale.json').readAsStringSync(),
              )
              as Map<String, dynamic>,
        ),
    };
  });

  test('uchala tilda kalitlar toʻplami bir xil', () {
    final reference = keysByLocale['uz']!;

    for (final locale in locales.where((l) => l != 'uz')) {
      final current = keysByLocale[locale]!;

      final missing = reference.difference(current).toList()..sort();
      final extra = current.difference(reference).toList()..sort();

      expect(
        missing,
        isEmpty,
        reason: '$locale.json da yetishmayapti:\n  ${missing.join('\n  ')}',
      );
      expect(
        extra,
        isEmpty,
        reason: '$locale.json da ortiqcha:\n  ${extra.join('\n  ')}',
      );
    }
  });

  test('boʻsh tarjima yoʻq', () {
    for (final locale in locales) {
      final raw =
          jsonDecode(
                File('assets/translations/$locale.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final empty = <String>[];
      _walk(raw, '', (key, value) {
        if (value.trim().isEmpty) empty.add(key);
      });
      expect(empty, isEmpty, reason: '$locale.json da boʻsh qiymat: $empty');
    }
  });
}

Set<String> _flatten(Map<String, dynamic> json) {
  final keys = <String>{};
  _walk(json, '', (key, _) => keys.add(key));
  return keys;
}

void _walk(
  Map<String, dynamic> json,
  String prefix,
  void Function(String key, String value) onLeaf,
) {
  json.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      _walk(value, path, onLeaf);
    } else {
      onLeaf(path, value.toString());
    }
  });
}
