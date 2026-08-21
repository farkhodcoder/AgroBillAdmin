import 'package:flutter/material.dart';

import 'theme_storage.dart';

/// Kunduzgi/tungi rejimni saqlaydigan kontroller.
///
/// NEGA `localStorage`, `admin_users` ustuni EMAS:
/// tema — qurilma darajasidagi ko'rinish sozlamasi, hisob sozlamasi emas.
/// Bir admin ofisdagi kompyuterda yorug', uydagi noutbukda qorong'i rejimni
/// xohlashi tabiiy. Til esa aksincha — u `admin_users.language_code` da,
/// chunki odamning tili qurilmadan qurilmaga o'zgarmaydi. Bundan tashqari
/// bu bazaga yangi ustun qo'shishni talab qilmaydi.
///
/// NEGA `shared_preferences` EMAS:
/// u asinxron ochiladi, ya'ni birinchi kadr sukut bo'yicha tema bilan
/// chiziladi va saqlangani keyin qo'llanadi — foydalanuvchi qorong'i rejimni
/// tanlagan bo'lsa ham sahifa oq "chaqnab" ochilardi. `localStorage` sinxron,
/// shuning uchun `runApp` dan oldin o'qib olinadi va chaqnash umuman yo'q.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(_restore());

  static ThemeMode _restore() => switch (readThemeMode()) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  void set(ThemeMode mode) {
    if (mode == value) return;
    value = mode;
    writeThemeMode(mode.name);
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
