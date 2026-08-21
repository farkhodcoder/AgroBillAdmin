import 'package:agrobilladminpc_web/app/admin_material_app.dart';
import 'package:agrobilladminpc_web/core/theme/theme_controller.dart';
import 'package:agrobilladminpc_web/data/repositories/admin_auth_repository.dart';
import 'package:agrobilladminpc_web/features/auth/cubit/admin_auth_cubit.dart';
import 'package:agrobilladminpc_web/features/auth/widgets/language_switch.dart';
import 'package:agrobilladminpc_web/features/auth/widgets/login_footer.dart';
import 'package:agrobilladminpc_web/ui/theme_switch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Til tanlagich haqiqatan ishlaydimi.
///
/// Foydalanuvchi «til o'zgartirish chiqmayapti» deganidan keyin yozildi.
/// Kod o'qish bilan sabab topilmadi — ikkita alohida xato bor edi va
/// ikkalasi ham faqat qurilgan vidjet daraxtida ko'rinadi.
///
/// BITTA test, uch bosqichda — ATAYLAB. `EasyLocalization` tarjimalarni
/// statik nazoratchida saqlaydi va bitta test faylida ikkinchi marta
/// yaratilganda daraxt bo'sh qoladi (har bir test fayli alohida izolatda
/// ishlaydi, alohida test emas). Shuning uchun bitta daraxt quriladi va
/// tekshiruvlar ketma-ket bajariladi — bu ayni paytda haqiqiy foydalanuvchi
/// yo'liga ham mos keladi.
void main() {
  testWidgets('til tanlagich: koʻrinadi, sigadi va matnni almashtiradi', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final auth = AdminAuthCubit(AdminAuthRepository());
    addTearDown(auth.close);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                // Kirish ekrani kabi: sarlavha `.tr()` orqali.
                Text('admin.auth.sign_in_title'.tr()),
                LoginFooter(controller: ThemeController()),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('uz'),
        child: Builder(
          builder: (context) => BlocProvider.value(
            value: auth,
            child: AdminMaterialApp(
              routerConfig: router,
              themeMode: ThemeMode.light,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // --- 1. Ikkala tanlagich ham koʻrinadi -----------------------------
    expect(find.byType(LanguageSwitch), findsOneWidget);
    expect(find.byType(ThemeSwitch), findsOneWidget);
    for (final label in ["O'zbekcha", 'Русский', 'English']) {
      expect(find.text(label), findsOneWidget, reason: '$label koʻrinmayapti');
    }

    // --- 2. Tor oynada qirqilmaydi -------------------------------------
    //
    // Toʻliq nomlar ~412px joy oladi. Bundan tor joyda `Row` sigʻmay
    // istisno koʻtarardi va tugmalarni QIRQARDI — foydalanuvchi til
    // tanlagichni umuman topolmasdi. Vidjet testi overflow'ni xato deb
    // hisoblaydi, shuning uchun regressiya darhol koʻrinadi.
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSwitch), findsOneWidget);
    expect(find.byType(ThemeSwitch), findsOneWidget);
    expect(
      find.text('RU'),
      findsOneWidget,
      reason: 'tor oynada qisqa kodlarga oʻtmadi',
    );

    // --- 3. Bosilganda SAHIFA MATNI ham almashadi ----------------------
    //
    // Eng muhim tekshiruv. `'kalit'.tr()` — InheritedWidget'ga bogʻlanmagan
    // statik qidiruv, ya'ni til almashganda sahifa qayta qurilishi uchun
    // sabab yoʻq. Xato shunday koʻrinardi: tanlagichdagi belgi koʻchadi,
    // lekin ekrandagi barcha matn eski tilda qoladi.
    final titleBefore = tester.widget<Text>(find.byType(Text).first).data;

    await tester.tap(find.text('RU'));
    await tester.pumpAndSettle();

    expect(
      tester.element(find.byType(LanguageSwitch)).locale.languageCode,
      'ru',
      reason: 'bosilgandan keyin locale almashmadi',
    );
    expect(
      tester.widget<Text>(find.byType(Text).first).data,
      isNot(titleBefore),
      reason:
          'locale oʻzgardi, lekin sahifadagi .tr() matni eski tilda qoldi — '
          'AdminMaterialApp dagi ValueKey(context.locale) olib tashlanganmi?',
    );
  });
}
