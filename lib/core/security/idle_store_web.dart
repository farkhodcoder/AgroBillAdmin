import 'package:web/web.dart' as web;

const _key = 'agrobill.admin.last_activity';

int? readLastActivity() {
  // "Saytlar ma'lumot saqlamasin" yoqilgan brauzerda `SecurityError` chiqadi —
  // panel bundan ochilmay qolmasligi kerak.
  try {
    final raw = web.window.localStorage.getItem(_key);
    return raw == null ? null : int.tryParse(raw);
  } catch (_) {
    return null;
  }
}

void writeLastActivity(int epochMs) {
  try {
    web.window.localStorage.setItem(_key, '$epochMs');
  } catch (_) {
    // Saqlanmadi — joriy tabda taymer baribir ishlaydi.
  }
}

void clearLastActivity() {
  try {
    web.window.localStorage.removeItem(_key);
  } catch (_) {
    // E'tiborsiz.
  }
}
