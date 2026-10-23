/// Ma'lumotnoma jadvallaridagi (`regions`, `districts`, `crop_types`,
/// `admin_roles`) nom ustuni.
///
/// Bazada faqat `name_uz`, `name_ru`, `name_en` bor. Ilgari ustun nomi
/// `'name_$locale'` deb yasalardi: turk tili tanlanganda `name_tr` so'ralardi,
/// PostgREST `.order('name_tr')` ni rad etardi (viloyat filtri bo'sh qolardi),
/// rollar matritsasi esa `null as String` bilan qulab tushardi.
///
/// Turkcha va kirill ataylab `name_uz` ga tushadi — mobil ilovadagi
/// `localizedName()` bilan bir xil qoida (atoqli otlar tarjima qilinmaydi).
String refNameColumn(String languageCode) => switch (languageCode) {
  'ru' => 'name_ru',
  'en' => 'name_en',
  _ => 'name_uz',
};

/// [row] dagi joriy tilga mos nom; u bo'sh bo'lsa `name_uz`.
String? refName(Map<String, dynamic>? row, String languageCode) {
  if (row == null) return null;
  return row[refNameColumn(languageCode)] as String? ??
      row['name_uz'] as String?;
}
