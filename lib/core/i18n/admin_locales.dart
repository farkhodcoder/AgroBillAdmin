import 'package:flutter/widgets.dart';

/// Panel tillari — **yagona manba**.
///
/// Ilgari ro'yxat uch joyda qattiq yozilgan edi: `main.dart` dagi
/// `supportedLocales`, `language_switch.dart` dagi `_languages` va
/// `app.dart`/`admin_auth_cubit.dart` dagi `Locale(code)`. Til qo'shilganda
/// ulardan birini unutish oson va xato JIM bo'ladi — `easy_localization`
/// yetishmayotgan kalit uchun istisno ko'tarmaydi, ekranda kalitning o'zi
/// chiqadi.
///
/// Kod bilan `Locale` orasidagi o'girish ham shu yerda, chunki `uz-Cyrl` ni
/// to'g'ridan-to'g'ri `Locale('uz-Cyrl')` qilib bo'lmaydi: u `languageCode`
/// ni "uz-cyrl" deb oladi va tarjima fayli topilmaydi.
abstract final class AdminLocales {
  const AdminLocales._();

  static const uz = Locale('uz');

  /// O'zbek tilining kirill yozuvi.
  ///
  /// `Locale('uz', 'Cyrl')` **emas** — ikkinchi parametr mamlakat kodi
  /// hisoblanadi va fayl `uz-CYRL.json` deb izlanardi.
  static final uzCyrl = Locale.fromSubtags(
    languageCode: 'uz',
    scriptCode: 'Cyrl',
  );
  static const ru = Locale('ru');
  static const en = Locale('en');
  static const tr = Locale('tr');

  /// Ekranda ko'rinadigan tartib.
  static final all = <AdminLocaleOption>[
    AdminLocaleOption(locale: uz, label: "O'zbekcha", short: 'UZ'),
    AdminLocaleOption(locale: uzCyrl, label: 'Ўзбекча', short: 'ЎЗ'),
    AdminLocaleOption(locale: ru, label: 'Русский', short: 'РУ'),
    AdminLocaleOption(locale: en, label: 'English', short: 'EN'),
    AdminLocaleOption(locale: tr, label: 'Türkçe', short: 'TR'),
  ];

  static List<Locale> get supported => all.map((o) => o.locale).toList();

  /// `admin_users.language_code` dagi qiymatdan `Locale` yasaydi.
  ///
  /// Noma'lum kod uchun `uz` qaytadi — baza `CHECK` i ruxsat bermasa ham
  /// eski qator yoki qo'lda tahrir bo'lishi mumkin, panel esa shunda ham
  /// ochilishi kerak.
  static Locale localeFor(String code) {
    for (final option in all) {
      if (tagFor(option.locale) == code) return option.locale;
    }
    return uz;
  }

  /// `Locale` dan baza kutadigan qiymat: `uz`, `uz-Cyrl`, `ru`, `en`, `tr`.
  static String tagFor(Locale locale) => locale.scriptCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.scriptCode}';

  /// Ikki lokal bir xilmi — yozuv bilan birga.
  ///
  /// `languageCode` bo'yicha solishtirib bo'lmaydi: `uz` va `uz-Cyrl`
  /// ikkalasida ham u `uz`, ya'ni ikkalasi "tanlangan" bo'lib ko'rinardi.
  static bool sameLocale(Locale a, Locale b) =>
      a.languageCode == b.languageCode &&
      a.scriptCode == b.scriptCode &&
      a.countryCode == b.countryCode;
}

class AdminLocaleOption {
  const AdminLocaleOption({
    required this.locale,
    required this.label,
    required this.short,
  });

  final Locale locale;

  /// Tilning **o'z** nomi — tarjima qilinmaydi.
  final String label;

  /// Tor joyda ko'rsatiladigan qisqa belgi.
  ///
  /// `languageCode.toUpperCase()` ishlatib bo'lmaydi: o'zbekning ikki yozuvi
  /// ham "UZ" berardi va ular ajralmasdi.
  final String short;
}
