import 'package:web/web.dart' as web;

/// Kalit `web/index.html` dagi bo'yashdan oldingi skript bilan bir xil
/// bo'lishi SHART — ikkalasi ayni bitta qiymatni o'qiydi.
const _key = 'agrobill.admin.theme';

String? readThemeMode() {
  // `localStorage` ga murojaat istisno ko'tarishi mumkin: brauzerda
  // "saytlar ma'lumot saqlamasin" yoqilgan bo'lsa `SecurityError` chiqadi.
  // Panel bundan ochilmay qolmasligi kerak.
  try {
    return web.window.localStorage.getItem(_key);
  } catch (_) {
    return null;
  }
}

void writeThemeMode(String value) {
  try {
    web.window.localStorage.setItem(_key, value);
  } catch (_) {
    // Saqlanmadi — joriy sessiyada baribir ishlaydi.
  }
}
