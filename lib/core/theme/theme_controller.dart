import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Kunduzgi/tungi rejimni saqlaydigan kontroller.
///
/// NEGA `localStorage`, `admin_users` ustuni EMAS:
/// tema — qurilma darajasidagi ko'rinish sozlamasi, hisob sozlamasi emas.
/// Bir admin ofisdagi kompyuterda yorug', uydagi noutbukda qorong'i rejimni
/// xohlashi tabiiy. Bundan tashqari bu bazaga yangi ustun qo'shishni talab
/// qilmaydi — mavjud sxemaga tegilmaydi.
///
/// NEGA `shared_preferences` EMAS:
/// u asinxron ochiladi, ya'ni birinchi kadr sukut bo'yicha tema bilan
/// chiziladi va saqlangani keyin qo'llanadi — foydalanuvchi qorong'i rejimni
/// tanlagan bo'lsa ham sahifa oq "chaqnab" ochilardi. `localStorage` sinxron,
/// shuning uchun `runApp` dan oldin o'qib olinadi va chaqnash umuman yo'q.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(_restore());

  /// Boshqa AgroBill kalitlari bilan to'qnashmasligi uchun prefiksli.
  static const _storageKey = 'agrobill.admin.theme';

  static ThemeMode _restore() {
    // `localStorage` ga murojaat istisno ko'tarishi mumkin: brauzerda
    // "saytlar ma'lumot saqlamasin" yoqilgan bo'lsa `SecurityError` chiqadi.
    // Bunday holatda panel ochilmay qolmasligi kerak — tizim temasiga
    // qaytamiz, faqat tanlov eslab qolinmaydi.
    try {
      return switch (web.window.localStorage.getItem(_storageKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  void set(ThemeMode mode) {
    if (mode == value) return;
    value = mode;
    try {
      web.window.localStorage.setItem(_storageKey, mode.name);
    } catch (_) {
      // Saqlanmadi — joriy sessiyada baribir ishlaydi.
    }
  }

  /// Tugma bosilganda: tizim -> yorug' -> qorong'i -> tizim.
  ///
  /// "Tizim" halqadan chiqarib tashlanmaydi: brauzer temasi kun davomida
  /// avtomatik o'zgaradigan sozlamada shu variant kerak bo'ladi.
  void cycle() => set(switch (value) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}
