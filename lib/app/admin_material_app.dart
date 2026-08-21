import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// `MaterialApp.router` ni til bilan to'g'ri bog'laydigan karkas.
///
/// NEGA `key: ValueKey(context.locale)`:
/// `'kalit'.tr()` — InheritedWidget'ga bog'lanmagan STATIK qidiruv. Ya'ni
/// til almashganda `.tr()` ishlatadigan sahifada qayta qurilish uchun
/// hech qanday sabab yo'q: u hech narsaga "obuna" bo'lmagan. `go_router`
/// esa sahifalarni o'z delegatida ushlab turadi va ularni qayta qurmaydi.
///
/// Natijada xato SHUNDAY ko'rinardi: tanlagichdagi belgi yangi tilga
/// ko'chadi (u `context.locale` ga bog'langan), lekin ekrandagi barcha
/// matn eski tilda qoladi — "til o'zgartirish ishlamayapti".
///
/// Kalit `context.locale` ga bog'langani uchun til almashganda butun
/// daraxt qaytadan quriladi va `.tr()` yangi tarjimani oladi. `GoRouter`
/// obyekti o'zgarmaydi, shuning uchun joriy manzil saqlanib qoladi.
///
/// Alohida vidjet, chunki `language_switch_test.dart` ayni shu sinfni
/// sinaydi — nusxasini emas. Aks holda test o'z nusxasidagi kalitni
/// tekshirib, ilovadan olib tashlanganini sezmasdi.
class AdminMaterialApp extends StatelessWidget {
  const AdminMaterialApp({
    super.key,
    required this.routerConfig,
    required this.themeMode,
  });

  final RouterConfig<Object> routerConfig;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      key: ValueKey(context.locale),

      title: 'AgroBill Admin',
      debugShowCheckedModeBanner: false,

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,

      routerConfig: routerConfig,
    );
  }
}
