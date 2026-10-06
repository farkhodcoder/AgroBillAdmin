import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/i18n/admin_locales.dart';
import 'core/supabase/db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manzil qatorida `#` bo'lmasin: admin panel URL lari ulashiladi va
  // xatcho'pga qo'yiladi (`/users/<id>` ko'rinishida).
  usePathUrlStrategy();

  await EasyLocalization.ensureInitialized();

  // Kalitlar berilmagan bo'lsa panel baribir ochiladi — dizayn tizimini
  // kalitsiz ko'rish mumkin bo'lsin (`AdminConfig.isConfigured`).
  await Db.init();

  await setupDependencies();

  runApp(
    EasyLocalization(
      // TTZ §9: o'zbek, rus va ingliz majburiy. Kirill yozuvi va turkcha
      // keyin qo'shildi — ro'yxat `AdminLocales` da, uch joyda takrorlanmasin.
      supportedLocales: AdminLocales.supported,
      path: 'assets/translations',
      fallbackLocale: AdminLocales.uz,
      // `uz-Cyrl.json` shu bayroq bilan yuklanadi: u mamlakat kodini tashlaydi,
      // lekin yozuv kodini (`scriptCode`) SAQLAYDI.
      useOnlyLangCode: true,
      child: const AdminApp(),
    ),
  );
}
