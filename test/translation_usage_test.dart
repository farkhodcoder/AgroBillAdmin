import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kodda ishlatilgan har bir tarjima kaliti JSON da bormi.
///
/// `translations_parity_test` uchala tilning bir-biriga mosligini
/// tekshiradi — lekin uchalasida ham YETISHMAYDIGAN kalitni topa olmaydi.
/// `easy_localization` bunday holatda xato bermaydi, oddiygina RAW KALITNI
/// ekranga chiqaradi (`admin.users.col_name`), ya'ni buzilish faqat o'sha
/// ekran ochilganda ko'rinadi.
///
/// Dinamik kalitlar (`'admin.activity.$code'`) ham tekshiriladi: prefiks
/// ajratib olinadi va JSON da o'sha bo'lim borligi talab qilinadi.
void main() {
  late final Map<String, dynamic> uz;
  late final Set<String> keys;

  setUpAll(() {
    uz =
        jsonDecode(File('assets/translations/uz.json').readAsStringSync())
            as Map<String, dynamic>;
    keys = _flatten(uz);
  });

  test('koddagi statik kalitlar JSON da bor', () {
    final used = _staticKey();
    expect(used, isNotEmpty, reason: 'lib/ dan kalit oʻqilmadi');

    final missing = used.where((k) => !keys.contains(k)).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason: 'uz.json da yoʻq:\n  ${missing.join('\n  ')}',
    );
  });

  test('dinamik kalitlarning boʻlimi JSON da bor', () {
    // `'admin.activity.$code'` -> `admin.activity`
    final prefixes = _scanLib(_dynamicPrefix);

    final missing = <String>[];
    for (final prefix in prefixes) {
      if (!_hasSection(uz, prefix)) missing.add(prefix);
    }
    missing.sort();

    expect(
      missing,
      isEmpty,
      reason: 'uz.json da bunday boʻlim yoʻq:\n  ${missing.join('\n  ')}',
    );
  });

  test('JSON da ishlatilmaydigan kalit yoʻq', () {
    // Bu tekshiruv KENG skanerdan foydalanadi: kalit `.tr()` yonida
    // turmasligi mumkin — tuple ichida (`('admin.nav.audit', Icons...)`),
    // xarita qiymatida (`admin_error_codes.dart`) yoki parametr default
    // qiymatida. Savol "shu kalitga umuman murojaat bormi", shuning uchun
    // istalgan matn literali yetarli.
    //
    // "Yetishmayapti" tekshiruvi esa aksincha TOR skaner ishlatadi: u
    // `.tr()` chaqiruvining kaliti borligini soʻraydi.
    final referenced = _scanLib(_anyKeyLiteral);
    final prefixes = _scanLib(_dynamicPrefix);

    final unused = keys.where((k) {
      if (referenced.contains(k)) return false;
      // Dinamik boʻlim ichidagi kalitlar (`admin.activity.farm_owner`)
      // koddan toʻgʻridan-toʻgʻri koʻrinmaydi.
      return !prefixes.any((p) => k.startsWith('$p.'));
    }).toList()..sort();

    expect(
      unused,
      isEmpty,
      reason:
          'JSON da bor, lekin kodda ishlatilmaydi '
          '(oʻchiring yoki ishlating):\n  ${unused.join('\n  ')}',
    );
  });
}

// Naqshlar ATAYLAB tor. Oddiy "nuqtali matn" qidiruvi ruxsat kodlarini
// (`'users.read'`), fayl yoʻllarini va paket nomlarini ham tarjima kaliti
// deb oʻqiydi — natijada test soxta xato beradi va unga ishonish toʻxtaydi.
// Shuning uchun faqat kalit HAQIQATAN ISHLATILGAN joylar sanaladi.

/// `'admin.users.col_name'.tr(` — toʻgʻridan-toʻgʻri chaqiruv.
final _trCall = RegExp(r"'([a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+)'\s*\.tr\(");

/// `labelKey: 'admin.users.col_name'` — vidjet ichida `.tr()` chaqiriladi.
final _keyParam = RegExp(
  r"\b(?:labelKey|hintKey|titleKey|messageKey)\s*:\s*"
  r"'([a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+)'",
);

/// `AppFailure(..., 'admin.errors.timeout')` — ikkinchi pozitsion argument.
final _failureKey = RegExp(
  r"AppFailure\([^)]*?'(admin\.[a-z0-9_.]+)'",
  dotAll: true,
);

/// `'admin.activity.$code'.tr(` kabi kalitlarning oʻzgarmas qismi.
final _dynamicPrefix = RegExp(
  r"'([a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)*)\.\$[^']*'\s*\.tr\(",
);

/// Istalgan `'admin.*'` yoki `'app.*'` matn literali — faqat
/// "ishlatilmayapti" tekshiruvi uchun. Ruxsat kodlari (`'users.read'`) va
/// fayl yoʻllari bu naqshga tushmaydi, chunki prefiks talab qilinadi.
final _anyKeyLiteral = RegExp(r"'((?:admin|app)(?:\.[a-z][a-z0-9_]*)+)'");

Set<String> _scanLib(RegExp pattern) {
  final found = <String>{};

  for (final file in Directory('lib').listSync(recursive: true)) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    for (final m in pattern.allMatches(file.readAsStringSync())) {
      found.add(m.group(1)!);
    }
  }
  return found;
}

Set<String> _staticKey() => {
  ..._scanLib(_trCall),
  ..._scanLib(_keyParam),
  ..._scanLib(_failureKey),
};

bool _hasSection(Map<String, dynamic> json, String path) {
  dynamic node = json;
  for (final part in path.split('.')) {
    if (node is! Map<String, dynamic> || !node.containsKey(part)) return false;
    node = node[part];
  }
  return node is Map;
}

Set<String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final keys = <String>{};
  json.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      keys.addAll(_flatten(value, path));
    } else {
      keys.add(path);
    }
  });
  return keys;
}
