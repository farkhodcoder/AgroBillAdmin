import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'app/di.dart';
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
      // TTZ §9: uchala til ham majburiy.
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('uz'),
      child: const AdminApp(),
    ),
  );
}
