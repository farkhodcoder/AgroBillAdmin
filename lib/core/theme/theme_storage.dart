import 'theme_storage_stub.dart'
    if (dart.library.js_interop) 'theme_storage_web.dart'
    as impl;

/// Tema tanlovini saqlaydigan qatlam.
///
/// NEGA SHARTLI IMPORT:
/// `package:web` faqat brauzerda mavjud. `theme_controller.dart` uni
/// to'g'ridan-to'g'ri import qilganda `flutter test` UMUMAN
/// KOMPILYATSIYA BO'LMAY qoldi — testlar Dart VM da ishlaydi, u yerda
/// `dart:js_interop` yo'q. Ya'ni tema tugmasiga tegadigan bironta vidjet
/// testini yozib bo'lmasdi.
///
/// Shartli import bu bog'liqlikni bitta faylga qamaydi: brauzerda
/// `localStorage` ishlaydi, boshqa hamma joyda (test, kelajakda desktop)
/// zararsiz "hech narsa saqlanmaydi" varianti.
String? readThemeMode() => impl.readThemeMode();

void writeThemeMode(String value) => impl.writeThemeMode(value);
